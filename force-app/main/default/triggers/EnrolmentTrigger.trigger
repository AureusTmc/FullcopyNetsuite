trigger EnrolmentTrigger on Enrolment__c (before Insert, after Insert,before Update,after Update, after delete,after undelete) {
    
    if(trigger.isBefore){
        // start: Nishi- 4-Aug-2020: for if enrolment created or updated and resource id 
        String enrollmentInstrumentRecTypeId = Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get(ConstantsClass.enrollmentInstrumentRecTypeName).getRecordTypeId();
        Map<string,Boolean> filterChangeEnrolmentMap = new Map<string,Boolean>();
        List<Enrolment__c> filterTeacherEnrolment = new list<Enrolment__c>();
        Set<String> teacherIds = new Set<String>();
        Set<String> centerIds = new Set<String>();
        Set<String> bookingDays = new  Set<String> ();
         // end : Nishi- 4-Aug-2020: for if enrolment created or updated and resource id 
         //By Rajesh, Lead conversion process on trial
         if(trigger.isInsert){
             List<Enrolment__c> processEnrList = new List<Enrolment__c>();
             Set<Id> parAccIds  = new Set<Id>();
             
             for(Enrolment__c enrol: trigger.new){
                 enrol.Name = 'New Enrolment Name';
                 
                 enrol.Lesson_Mode__c= ConstantsClass.InCentre; // nishi :4 -aug-2020:for set default Lesson Mode is In center
                 if(enrol.Parent__c != null && enrol.Type__c == ConstantsClass.trialStatus && enrol.Stage__c == ConstantsClass.requestedSubStatus){
                     processEnrList.add(enrol);
                     parAccIds.add(enrol.Parent__c);
                 }
                  // start: Nishi- 4-Aug-2020: for if enrolment created or updated and resource id not found then 
                    //we added resource Id using teacher Working hrs.
                 if(string.IsBlank(enrol.Resource__c) && enrol.RecordTypeId != enrollmentInstrumentRecTypeId){
                    if(string.IsNotBlank(enrol.Teacher__c) && enrol.Trial_Date__c != null && enrol.Trial_Start_Time__c != null){
                        filterTeacherEnrolment.add(enrol);
                        filterChangeEnrolmentMap.put(enrol.id,false);
                        teacherIds.add(enrol.Teacher__c);
                        centerIds.add(enrol.Center__c);
                        bookingDays.add(DateTime.newInstance(enrol.Trial_Date__c, enrol.Trial_Start_Time__c).format('EEE'));
                    }
                }
                 // end: Nishi- 4-Aug-2020: for if enrolment created or updated and resource id not found then 
                //we added resource Id using teacher Working hrs.
             }
             
             if(processEnrList.size() > 0)
                 EnrolmentTriggerHandler.leadConversionForTrialEnrl(processEnrList, parAccIds);
             if(filterTeacherEnrolment != null && filterTeacherEnrolment.size() > 0){
                EnrolmentTriggerHandler.populateResourceInEnrolment(filterTeacherEnrolment,teacherIds,centerIds,bookingDays,true,filterChangeEnrolmentMap);
             }
         } 
          // start: Nishi- 4-Aug-2020: for if enrolment created or updated and resource id not found or if teacher will be changed 
        //we added resource Id using teacher Working hrs.
         if(trigger.isUpdate){
              
            for(Enrolment__c enr : trigger.new){
                Enrolment__c oldenrol = Trigger.oldMap.get(enr.Id);// Access the "old" record by its ID in Trigger.oldMap
                if(enr.RecordTypeId != enrollmentInstrumentRecTypeId){
                    if(string.IsNotBlank(enr.Teacher__c) && 
                       (oldenrol.Teacher__c != enr.Teacher__c || oldenrol.Lessons_Start_Date__c != enr.Lessons_Start_Date__c || 
                        oldenrol.Lesson_Day__c != enr.Lesson_Day__c || oldenrol.Lesson_Start_time__c != enr.Lesson_Start_time__c)){
                            filterTeacherEnrolment.add(enr);
                            teacherIds.add(enr.Teacher__c);
                            centerIds.add(enr.Center__c);
                            if(oldenrol.Lessons_Start_Date__c != enr.Lessons_Start_Date__c && enr.Lessons_Start_Date__c != null && enr.Lesson_Start_time__c != null){
                                bookingDays.add(DateTime.newInstance(enr.Lessons_Start_Date__c, enr.Lesson_Start_time__c).format('EEE'));
                                filterChangeEnrolmentMap.put(enr.id,true);
                            }else if(oldenrol.Lesson_Day__c != enr.Lesson_Day__c && string.isnotBlank(enr.Lesson_Day__c) && enr.Lesson_Start_time__c != null){
                                bookingDays.add(enr.Lesson_Day__c.left(3));  
                                filterChangeEnrolmentMap.put(enr.id,false);
                            }else if(oldenrol.Lesson_Start_time__c != enr.Lesson_Start_time__c && enr.Lesson_Start_time__c != null){
                                if(string.isnotBlank(enr.Lesson_Day__c)){
                                    bookingDays.add(enr.Lesson_Day__c.left(3));  
                                    filterChangeEnrolmentMap.put(enr.id,false);
                                }else if(enr.Lessons_Start_Date__c != null ){
                                    bookingDays.add(DateTime.newInstance(enr.Lessons_Start_Date__c, enr.Lesson_Start_time__c).format('EEE'));
                                    filterChangeEnrolmentMap.put(enr.id,true);
                                }
                            }  
                    }
                }
            } 
             if(filterTeacherEnrolment != null && filterTeacherEnrolment.size() > 0){
                   EnrolmentTriggerHandler.populateResourceInEnrolment(filterTeacherEnrolment,teacherIds,centerIds,bookingDays,false,filterChangeEnrolmentMap);
            
             }
         }
        
        // end: Nishi- 4-Aug-2020: for if enrolment created or updated and resource id not found or if teacher will be changed
        //we added resource Id using teacher Working hrs.
         
    
    }else if(trigger.isAfter){
         //commented by nishi: 7-aug: for deploy Only resource CHnages 
          Set<String> referredByIds = new Set<String>(); // add by nishi: 5-Aug-2020: for rollup referredBy Ids
        if(trigger.isInsert){
            //By Rajesh (Date 6-4-2019), This process is used to manage case(Sales Enquiry) for the trial request
            List<Enrolment__c> processEnrList = new List<Enrolment__c>();
             
             String enrollmentInstrumentRecTypeId = Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get(ConstantsClass.enrollmentInstrumentRecTypeName).getRecordTypeId();
       
            for(Enrolment__c enrol: trigger.new){
                if(enrol.Parent__c != null && enrol.Type__c == ConstantsClass.trialStatus && enrol.Stage__c == ConstantsClass.requestedSubStatus)
                    processEnrList.add(enrol);
              //  else if(enrol.Parent__c != null && enrol.Type__c == ConstantsClass.enrollmentTypeInstrument && enrol.Stage__c == ConstantsClass.enrollmentPianoViewingBookedStage)
                   // processEnrList.add(enrol);
                //Start: added by nishi: 5-Aug-2020: for rollup referredBy Ids
                 //commented by nishi: 7-aug: for deploy Only resource CHnages
                 if(string.isNotBlank(enrol.Referred_by__c) ){
                     referredByIds.add(enrol.Referred_by__c);
                } 
                 //commented by nishi: 7-aug: for deploy Only resource CHnages
                //end added by nishi: 5-Aug-2020: for rollup referredBy Ids  
            }
             
            if(processEnrList.size() > 0)   
                EnrolmentTriggerHandler.manageSalesEnquiryCase(processEnrList);
            //new EnrolmentTriggerHandler().manageSalesEnquiry();
            //Merge the Code of 2nd Trigger UpdateEnrolmentNo

            
            
        }if(trigger.isUpdate){
            //By Ravi, Enrolment Cancellation process  (//Process on cancellation)
            list<Enrolment__c> enrolList = new list<Enrolment__c>();
            for(Enrolment__c enrol:trigger.new){
                Enrolment__c oldenrol = Trigger.oldMap.get(enrol.Id);// Access the "old" record by its ID in Trigger.oldMap
                String oldEnrolment = oldEnrol.Stage__c;
                String newEnrolment = Enrol.Stage__c;
                if(enrol.Stage__c == 'Cancelled' && enrol.Type__c =='Trial' && oldEnrolment != newEnrolment){
                    enrolList.add(enrol);
                }
                //Start: added by nishi: 5-Aug-2020: for rollup referredBy Ids if Referred_by__c changed
                 //commented by nishi: 7-aug: for deploy Only resource CHnages
                 if(string.isNotBlank(enrol.Referred_by__c) && (enrol.Referred_by__c != oldenrol.Referred_by__c || oldEnrolment != newEnrolment)){
                     referredByIds.add(enrol.Referred_by__c);
                     referredByIds.add(oldenrol.Referred_by__c);
                 } 
                 //commented by nishi: 7-aug: for deploy Only resource CHnages
                //end: added by nishi: 5-Aug-2020: for rollup referredBy Ids if Referred_by__c if is changed
            }
            if(enrolList.size()>0)
                 EnrolmentTriggerHandler.DelBookingCancellation(enrolList);
            
            //@By Rajesh (Date 03-04-2019), Update Lead Case and opportunity stages for the Sales enquiry process
            list<Enrolment__c> enrList = new list<Enrolment__c>();
            for(Enrolment__c enrol:trigger.new){
                if((String.isNotBlank(enrol.Type__c) && String.isNotBlank(enrol.Stage__c)) && enrol.Type__c != Trigger.oldMap.get(enrol.Id).Type__c || enrol.Stage__c != Trigger.oldMap.get(enrol.Id).Stage__c)
                    enrList.add(enrol);
            } 
            if(enrList.size() > 0 && EnrolmentTriggerHandler.isFirstTime){
                EnrolmentTriggerHandler.isFirstTime = False;
                EnrolmentTriggerHandler.updateStatusForSalesProcess(enrList);
            }
            
            Map<String,Enrolment__c> mapOfCancelEnrol = new Map<String,Enrolment__c>();
            /*
            // @By Arpit , to centerlize Package Upgrade and Downgrade functionality  
            Map<String,Enrolment__c> mapOfEnrolment = new Map<String,Enrolment__c>();
            Map<String,String> mapOfOldEnrolPackage = new Map<String,String>();
            //@By Jatin, to update teacher and Booking Start Time as well
            Map<String, String> mapOfNewTeachers = new Map<String, String>();  
            Map<String, Time> mapOfNewStartTime = new Map<String, Time>();
            //List<Enrolment__c> listOFCancelEnrol = new List<Enrolment__c>();
            Map<String,Enrolment__c> mapOfCancelEnrol = new Map<String,Enrolment__c>();
            System.debug('Enrolment Trigger...');
            for(Enrolment__c enrol:trigger.new){
                Enrolment__c oldenrol = Trigger.oldMap.get(enrol.Id);// Access the "old" record by its ID in Trigger.oldMap
                mapOfEnrolment.put(enrol.Id,enrol);
                if(String.isNotBlank(oldEnrol.Package__c) && String.isNotBlank(enrol.Package__c) && oldEnrol.Package__c != enrol.Package__c){
                   
                   mapOfOldEnrolPackage.put(enrol.Id,oldEnrol.Package__c); 
                }
                if(String.isNotBlank(enrol.Teacher__c) && String.isNotBlank(oldenrol.Teacher__c) && oldEnrol.Teacher__c != enrol.Teacher__c){
                    mapOfNewTeachers.put(enrol.Id, enrol.Teacher__c);
                }
                
                if(enrol.Lesson_Start_time__c != NULL && oldenrol.Lesson_Start_time__c != NULL && oldEnrol.Lesson_Start_time__c != enrol.Lesson_Start_time__c){
                    mapOfNewStartTime.put(enrol.Id, enrol.Lesson_Start_time__c);
                }
                if(oldEnrol.Stage__c != enrol.stage__c && enrol.stage__c == 'Cancelled' && enrol.Type__c == 'Regular'){
                    //listOfCancelEnrol.add(enrol);
                    mapOfCancelEnrol.put(enrol.Id,enrol);
 
                }
            }
            System.debug('mapOfNewStartTime '+mapOfNewStartTime);
            System.debug('mapOfNewTeachers '+mapOfNewTeachers);
            System.debug('mapOfOldEnrolPackage '+mapOfOldEnrolPackage);
            if(mapOfEnrolment.size() > 0 && (mapOfOldEnrolPackage.size() > 0 || mapOfNewTeachers.size() > 0 || mapOfNewStartTime.size() > 0)){
                System.debug('trigger fired');
                EnrolmentTriggerHandler.ProcessBookingAfterPackageChange(mapOfEnrolment, mapOfOldEnrolPackage, mapOfNewTeachers, mapOfNewStartTime);    
            } 
            */
            Map<String, Enrolment__c> mapOfNewEnrolment = new Map<String, Enrolment__c>();      
            Boolean flag;       
            for(Enrolment__c enrolObj : Trigger.new){       
                Enrolment__c oldEnrol = Trigger.oldMap.get(enrolObj.Id);        
                flag = false;       
                        
                if(String.isNotBlank(oldEnrol.Package__c) && String.isNotBlank(enrolObj.Package__c) && oldEnrol.Package__c != enrolObj.Package__c){     
                    flag = true;        
                }       
                        
                if(String.isNotBlank(enrolObj.Teacher__c) && String.isNotBlank(oldEnrol.Teacher__c) && oldEnrol.Teacher__c != enrolObj.Teacher__c){     
                    flag = true;        
                }       
                        
                if(enrolObj.Lesson_Start_time__c != NULL && oldEnrol.Lesson_Start_time__c != NULL && oldEnrol.Lesson_Start_time__c != enrolObj.Lesson_Start_time__c){       
                    flag = true;        
                }       
                        
                if(oldEnrol.Stage__c != enrolObj.stage__c && enrolObj.stage__c == 'Cancelled' && enrolObj.Type__c == 'Regular'){        
                    //listOfCancelEnrol.add(enrol);     
                    mapOfCancelEnrol.put(enrolObj.Id,enrolObj);     
        
                }       
                if(flag){       
                    mapOfNewEnrolment.put(enrolObj.Id, enrolObj);       
                }       
            }       
                    
            if(mapOfNewEnrolment.size() > 0){       
                EnrolmentTriggerHandler.updateBookingOfEnrolment(mapOfNewEnrolment);        
            }
            if(mapOfCancelEnrol.size() > 0){
                EnrolmentTriggerHandler.processCancellation(mapOfCancelEnrol);
                //EnrolmentTriggerHandler.DelBookingCancellation(enrolList);
            }
                 
        }
        //start: added by nishi: 5-Aug-2020: for rollup referredBy Ids
         //commented by nishi: 7-aug: for deploy Only resource CHnages
         if(referredByIds != null && referredByIds.size() > 0){
             EnrolmentTriggerHandler.rollUpreferredByIdsTotalEnrolment(referredByIds);
         }
         //commented by nishi: 7-aug: for deploy Only resource CHnages
         //end: added by nishi: 5-Aug-2020: for rollup referredBy Ids

        //Code Merge of 2nd Trigger UpdateEnrolmentNo
        if(Trigger.isInsert || Trigger.isUndelete){
            EnrolmentTriggerHandler.updatetotalEnrolment(Trigger.New);
        }
        
          if(Trigger.isDelete){
            EnrolmentTriggerHandler.updatetotalEnrolment(Trigger.Old);
        } 
        if(Trigger.isUpdate){
            List<Enrolment__c> enrList= new List<Enrolment__c>();
            for(Enrolment__c enrObj:Trigger.New){
                if (Trigger.oldmap.get(enrObj.Id).Type__c != enrObj.Type__c 
                || Trigger.oldmap.get(enrObj.Id).Stage__c != enrObj.Stage__c 
                || Trigger.oldmap.get(enrObj.Id).Package_Process_Status__c != enrObj.Package_Process_Status__c ||
                Trigger.oldmap.get(enrObj.Id).Package_Process_Type__c != enrObj.Package_Process_Type__c) 
                {
                    enrList.add(enrObj);
                                                                        
                }
                //system.debug('---enrList'+enrList);
                if(enrList.size()>0){
                   // system.debug('enrList'+enrList);
                   EnrolmentTriggerHandler.updatetotalEnrolment(enrList); 
                }
                
            }
          
        }
       
        // added by Jatin:27-Dec-2019 :For calculate group type enrolment check CLass Id is exist or not
        // if find classId or if enrolment withdrawal then update '# of units' field in class object
        Set<Id> listOfClass= new Set<Id>();
        Set<String> enrolmentIds = new Set<String>();
        String enrollmentInstrumentRecTypeId = Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get(ConstantsClass.enrollmentInstrumentRecTypeName).getRecordTypeId();
        Set<String> enrolmentIdPandaDoc = new Set<String>();
        if(Trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate){
             
            for(Enrolment__c enrObj:Trigger.New){
                
                 if((Trigger.isInsert || Trigger.isUndelete) && string.isNotBlank(enrObj.Class__c)){
                     listOfClass.add(enrObj.Class__c);
                 }else if(Trigger.isUpdate){
                               
                     
                     if (Trigger.oldmap.get(enrObj.Id).Class__c != enrObj.Class__c ){
                        if(string.isNotBlank(enrObj.Class__c)){
                            listOfClass.add(enrObj.Class__c);
                        }
                         if(string.isNotBlank(Trigger.oldmap.get(enrObj.Id).Class__c)){
                            listOfClass.add(Trigger.oldmap.get(enrObj.Id).Class__c);
                        }
                        
                    } else if ((Trigger.oldmap.get(enrObj.Id).Type__c != enrObj.Type__c 
                            || Trigger.oldmap.get(enrObj.Id).Stage__c != enrObj.Stage__c 
                            || Trigger.oldmap.get(enrObj.Id).Package_Process_Status__c != enrObj.Package_Process_Status__c ||
                            Trigger.oldmap.get(enrObj.Id).Package_Process_Type__c != enrObj.Package_Process_Type__c)
                            && string.isNotBlank(enrObj.Class__c)) {
                            listOfClass.add(enrObj.Class__c);
                        }
                    // added by jatin: 30-Dec-2019 : for Rental invoice will be generated and sent to the customer via email along with the confirmed timeslot
                    if(enrObj.Type__c == ConstantsClass.enrollmentTypeInstrument && enrObj.RecordTypeId == enrollmentInstrumentRecTypeId && enrObj.Stage__c ==ConstantsClass.enrollmentPianoRentalActiveStage){
                        if((Trigger.oldmap.get(enrObj.Id).Final_Delivery_date__c != enrObj.Final_Delivery_date__c 
                                && Trigger.oldmap.get(enrObj.Id).Final_Delivery_date__c == null 
                                &&  enrObj.Final_Delivery_date__c != Null )
                            && (Trigger.oldmap.get(enrObj.Id).Final_Delivery_Timeslot__c != enrObj.Final_Delivery_Timeslot__c
                                && Trigger.oldmap.get(enrObj.Id).Final_Delivery_Timeslot__c == null
                                && enrObj.Final_Delivery_Timeslot__c != Null)){
                                dateTime finalDeliveryDate = Datetime.newInstance(enrObj.Final_Delivery_date__c, enrObj.Final_Delivery_Timeslot__c);
                                Decimal Hours = (decimal.valueOf((finalDeliveryDate.getTime() - DateTime.now().getTime())))/(1000*60*60);
                                // check singup time is expire or not
                                if(finalDeliveryDate.date() < DateTime.now().date()){
                                    enrObj.Final_Delivery_date__c.AddError('Final Delivery Date Less then System Date');
                                }/*else if(finalDeliveryDate.date() == DateTime.now().date() && Hours  < 0){
                                    enrObj.Final_Delivery_Timeslot__c.AddError('Final Delivery Time Less then System Time'+DateTime.now()+'--'+finalDeliveryDate); 
                                }*/else{
                                    if(string.isBlank(enrObj.Aggrement_Id__c)){
                                        enrolmentIds.add(enrObj.id);
                                        // @@jatin: 16-jan-2020: for create pandaDoc document
                                        enrolmentIdPandaDoc.add(enrObj.id); 
                                    }
                                }
                        }else if(Trigger.oldmap.get(enrObj.Id).Final_Delivery_date__c != enrObj.Final_Delivery_date__c &&
                            Trigger.oldmap.get(enrObj.Id).Final_Delivery_Timeslot__c == enrObj.Final_Delivery_Timeslot__c) {
                            if(enrObj.Final_Delivery_Timeslot__c == Null){
                                enrObj.Final_Delivery_Timeslot__c.AddError('Select Final Delivery Timeslot');   
                            }else if(enrObj.Final_Delivery_date__c == Null){
                                enrObj.Final_Delivery_date__c.AddError('Select Final Delivery date');   
                            }else{  
                                dateTime finalDeliveryDate = Datetime.newInstance(enrObj.Final_Delivery_date__c, enrObj.Final_Delivery_Timeslot__c);
                                Decimal Hours = (decimal.valueOf((finalDeliveryDate.getTime() - DateTime.now().getTime())))/(1000*60*60);
                                // check singup time is expire or not
                                if(finalDeliveryDate.date() < DateTime.now().date()){
                                    enrObj.Final_Delivery_date__c.AddError('Final Delivery Date Less then Today');
                                }/*else if(finalDeliveryDate.date() == DateTime.now().date() && Hours  < 0){
                                    enrObj.Final_Delivery_Timeslot__c.AddError('Final Delivery Time Less then System Time'+DateTime.now()+'--'+finalDeliveryDate); 
                                } */
                            }
                        }else if(Trigger.oldmap.get(enrObj.Id).Final_Delivery_date__c == enrObj.Final_Delivery_date__c &&
                            Trigger.oldmap.get(enrObj.Id).Final_Delivery_Timeslot__c != enrObj.Final_Delivery_Timeslot__c){
                            if(enrObj.Final_Delivery_date__c == Null){
                                enrObj.Final_Delivery_date__c.AddError('Select Final Delivery date');   
                            } else if(enrObj.Final_Delivery_Timeslot__c == Null){
                                    enrObj.Final_Delivery_Timeslot__c.AddError('Select Final Delivery Timeslot');   
                            }else{  
                                dateTime finalDeliveryDate = Datetime.newInstance(enrObj.Final_Delivery_date__c, enrObj.Final_Delivery_Timeslot__c);
                                Decimal Hours = (decimal.valueOf((finalDeliveryDate.getTime() - DateTime.now().getTime())))/(1000*60*60);
                                // check singup time is expire or not
                                if(finalDeliveryDate.date() < DateTime.now().date()){
                                    enrObj.Final_Delivery_date__c.AddError('Final Delivery Date Less then System Date');
                                }/*else if(finalDeliveryDate.date() == DateTime.now().date() && Hours  < 0){
                                    enrObj.Final_Delivery_Timeslot__c.AddError('Final Delivery Time Less then System Time'+DateTime.now()+'--'+finalDeliveryDate); 
                                } */
                            } 
                        }else if((Trigger.oldmap.get(enrObj.Id).Final_Delivery_date__c != enrObj.Final_Delivery_date__c 
                                && Trigger.oldmap.get(enrObj.Id).Final_Delivery_date__c != null 
                                &&  enrObj.Final_Delivery_date__c != Null )
                            && (Trigger.oldmap.get(enrObj.Id).Final_Delivery_Timeslot__c != enrObj.Final_Delivery_Timeslot__c
                                && Trigger.oldmap.get(enrObj.Id).Final_Delivery_Timeslot__c != null
                                && enrObj.Final_Delivery_Timeslot__c != Null)){
                                    dateTime finalDeliveryDate = Datetime.newInstance(enrObj.Final_Delivery_date__c, enrObj.Final_Delivery_Timeslot__c);
                                    Decimal Hours = (decimal.valueOf((finalDeliveryDate.getTime() - DateTime.now().getTime())))/(1000*60*60);
                                    // check singup time is expire or not
                                    if(finalDeliveryDate.date() < DateTime.now().date()){
                                        enrObj.Final_Delivery_date__c.AddError('Final Delivery Date Less then System Date');
                                    }/*else if(finalDeliveryDate.date() == DateTime.now().date() && Hours  < 0){
                                        enrObj.Final_Delivery_Timeslot__c.AddError('Final Delivery Time Less then System Time'+DateTime.now()+'--'+finalDeliveryDate); 
                                    } */
                                }
                    }  
                 } 
            }
        }
         if(Trigger.isDelete ){
            for(Enrolment__c enrObj:Trigger.old){
                if(string.isNotBlank(enrObj.Class__c)){
                     listOfClass.add(enrObj.Class__c);
                 }
            }
        }
        // jatin: 16-jan-2020: for create pandaDoc Document
        if(enrolmentIdPandaDoc.size() > 0){   
            EnrolmentTriggerHandler.processEnrPandaDocList(enrolmentIdPandaDoc); 
        }
        if(listOfClass != null && listOfClass.size()>0){
            EnrolmentTriggerHandler.updateClassTotalEnrolment(listOfClass); 
        }
        system.debug('enrolmentIdPandaDoc'+enrolmentIdPandaDoc);
         system.debug('listOfClass'+listOfClass);
          system.debug('enrolmentIds'+enrolmentIds);
        if(enrolmentIds != null && enrolmentIds.size() > 0){
            EnrolmentTriggerHandler.generateRentalInvoice(enrolmentIds);
        }
    }


    
}