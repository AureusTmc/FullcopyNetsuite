public class LeaveRequestHelper {
    // fetching teacher name from the constant class
    private static string Teacher = ConstantsClass.teacherRecTypeName;
    // fetching the name of lesson from constant class
    private static string lesson = ConstantsClass.recordTypeLesson;
    public static void sickLeave(list<Leave_Request__c> leaveReqList){
        system.debug('leaveReqList'+leaveReqList);
        // sicleave recorrd type id
   		Id sickRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        string message='Success';
        Savepoint sp = Database.setSavepoint();
        try{
            // defined to store the teacher record Type
            Id TeacherRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Teacher).getRecordTypeId();
            // defined to get the lesson record type of booking 
            string lessonRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
            // defined to store the case list when booking is cancelled
            List<Case> casList = new List<Case>();
            // defined to store the other than sick type record case list when booking is cancelled
            List<Case> notSickcasList = new List<Case>();
            // defined to map the teacher with the leave request object
            map<Id,Leave_Request__c> mapToTeacherDate=new map<Id,Leave_Request__c>();
            // defind to map the teacher with the booking 
            map<Id,List<Booking__c>> mapToTechrBooking = new map<Id,List<Booking__c>>();
            // For Placeholder Booking against Regular
            list<Booking__c> placeholdeBooking = new list<Booking__c>();
            // defined to update the booking id for the make-up type booking 
            list<Booking__c> updateMakeupList = new list<Booking__c>();
            // defined to map to working hour
            map<string,string> mapToworkinghour = new map<string,string>();
            // update leave request Calendar_Update_Process__c with true
            List<Leave_Request__c> leaveUpdateList= new List<Leave_Request__c>();
            for(Leave_Request__c reqLeavObj:leaveReqList){
                mapToTeacherDate.put(reqLeavObj.Employee__c,reqLeavObj);
            }
            system.debug('mapToTeacherDate'+mapToTeacherDate);
            List<Booking__c> bookingMakeUpList = new List<Booking__c>();
            Map<Id,Booking__c> bookingMakeUpMap = new Map<Id,Booking__c>();
            List<Booking__c> cancelBookingList = new List<Booking__c>();
            
            // added by nishi: 22-jul-2020: for manage ossia organization student we added 180 days in expiry dates
            List<Ossia_Organisation_Settings__mdt> listOfOssia_Organisation_Settings = [SELECT Id, DeveloperName, MasterLabel, 
            Language, NamespacePrefix, Label, QualifiedApiName, Makeup_Expiry_Days__c,
            Makeup_Expiry_Days_Teacher__c FROM Ossia_Organisation_Settings__mdt
            WHERE Label =:System.Label.Ossia_Organisation_Name];
            // added by nishi: 22-jul-2020: for manage ossia organization student  we added 180 days in expiry dates

            // fetching the booking list as per the teacher ID
            for(Booking__c bkgObj:[select Id,Duration__c,End_Time__c,Teacher_Account__r.Name,Teacher_Account__r.Id,
                                Type__c,Status__c,Booking_Date__c,Start_Time__c,Parent__c,Student__c,Parent__r.PersonContactId,
                                Parent__r.personEmail,Center__c,Center__r.Location__c,Student__r.Name,Teacher_Account__c,Enrolment__c,
                                Available_Make_up_Units__c,Make_up_Utilize_Bookings__c ,
                                // added by nishi : 22-jul-2020:start: for manage ossia oranization students 
                                Center__r.Name,Center__r.Organisation__r.Name
                                // added by nishi : 22-jul-2020:start: for manage ossia oranization students 
                                from Booking__c 
                                where Teacher_Account__c in:mapToTeacherDate.keySet() 
                                and Booking_Date__c>=today 
                                and  Type__c in ('Trial','Regular','Make-up','Ad-hoc','Busy') 
                                And Status__c in ('Pending','Scheduled') 
                                AND Category__c Not in ('Leave','Placeholder','Holiday')
                                ]){
                
                if(mapToTeacherDate.containsKey(bkgObj.Teacher_Account__c)){
                    Leave_Request__c reqLeavObj = mapToTeacherDate.get(bkgObj.Teacher_Account__c);
                    if(bkgObj.Booking_Date__c >= reqLeavObj.Leave_Start_Date__c && bkgObj.Booking_Date__c <= reqLeavObj.Leave_End_Date__c){
                        // Creating Case For each Booking except Busy and Trial
                            if(bkgObj.Type__c != 'Busy' && bkgObj.Type__c != 'Trial' && reqLeavObj.RecordTypeId==sickRecordTypeId  && reqLeavObj.Sick_leave_start_Time__c != null){
                               
                                if( (bkgObj.Start_Time__c>=reqLeavObj.Sick_leave_start_Time__c && reqLeavObj.Leave_Start_Date__c ==bkgObj.Booking_Date__c )
                                   || reqLeavObj.Leave_Start_Date__c !=bkgObj.Booking_Date__c){
                                       Case casObj = new Case(Status='Closed',Type=bkgObj.Type__c,Origin='Automation',Priority='Medium',Booking__c=bkgObj.Id,
                                                              Centre_Name__c=bkgObj.Center__c,Student_Name__c=bkgObj.Student__c,AccountId=bkgObj.Parent__c,
                                                              Location__c=bkgObj.Center__r.Location__c,Leave_Start_Date__c=reqLeavObj.Leave_Start_Date__c,Leave_End_Date__c=reqLeavObj.Leave_End_Date__c);
                                       casList.add(casObj);
                                   }
                            }else if(bkgObj.Type__c !='Trial' && bkgObj.Type__c != 'Busy' && reqLeavObj.RecordTypeId==sickRecordTypeId  && reqLeavObj.Sick_leave_start_Time__c == null){
                                Case casObj = new Case(Status='Closed',Type=bkgObj.Type__c,Origin='Automation',Priority='Medium',Booking__c=bkgObj.Id,
                                                       Centre_Name__c=bkgObj.Center__c,Student_Name__c=bkgObj.Student__c,AccountId=bkgObj.Parent__c,
                                                       Location__c=bkgObj.Center__r.Location__c,Leave_Start_Date__c=reqLeavObj.Leave_Start_Date__c,Leave_End_Date__c=reqLeavObj.Leave_End_Date__c);
                                casList.add(casObj);  
                            }
                        // added on 4th dec will create case accordingly time in Sick_leave_start_Time__c
                            if(bkgObj.Type__c != 'Busy' && bkgObj.Type__c != 'Trial' && reqLeavObj.RecordTypeId !=sickRecordTypeId && reqLeavObj.Sick_leave_start_Time__c != null){
                                
                                if( (bkgObj.Start_Time__c>=reqLeavObj.Sick_leave_start_Time__c && reqLeavObj.Leave_Start_Date__c ==bkgObj.Booking_Date__c )
                                   || reqLeavObj.Leave_Start_Date__c !=bkgObj.Booking_Date__c){
                                       Case casObj = new Case(Status='Closed',Type=bkgObj.Type__c,Origin='Automation',Priority='Medium',Booking__c=bkgObj.Id,
                                                              Centre_Name__c=bkgObj.Center__c,Student_Name__c=bkgObj.Student__c,AccountId=bkgObj.Parent__c,
                                                              Location__c=bkgObj.Center__r.Location__c,Leave_Start_Date__c=reqLeavObj.Leave_Start_Date__c,Leave_End_Date__c=reqLeavObj.Leave_End_Date__c);
                                       notSickcasList.add(casObj);  
                                   }
                            }else if(bkgObj.Type__c !='Trial' && bkgObj.Type__c != 'Busy' && reqLeavObj.RecordTypeId !=sickRecordTypeId  && reqLeavObj.Sick_leave_start_Time__c == null){
                                Case casObj = new Case(Status='Closed',Type=bkgObj.Type__c,Origin='Automation',Priority='Medium',Booking__c=bkgObj.Id,
                                                       Centre_Name__c=bkgObj.Center__c,Student_Name__c=bkgObj.Student__c,AccountId=bkgObj.Parent__c,
                                                       Location__c=bkgObj.Center__r.Location__c,Leave_Start_Date__c=reqLeavObj.Leave_Start_Date__c,Leave_End_Date__c=reqLeavObj.Leave_End_Date__c);
                                notSickcasList.add(casObj);  
                            }
                        // Updating Booking Status To Cancel except for Trial
                        // added on 4th dec 2019 it will cancel the booking as per time in Sick Leave Start Time
                        if(bkgObj.Type__c !='Trial' && reqLeavObj.Sick_leave_start_Time__c != null){
                            if( (bkgObj.Start_Time__c>=reqLeavObj.Sick_leave_start_Time__c && reqLeavObj.Leave_Start_Date__c ==bkgObj.Booking_Date__c )
                               || reqLeavObj.Leave_Start_Date__c !=bkgObj.Booking_Date__c){
                                   bkgObj.Status__c='Canceled';
                                   bkgObj.Cancellation_Reason__c= reqLeavObj.RecordTypeId==sickRecordTypeId ? 'Teacher MC':'Teacher Leave';
                                   cancelBookingList.add(bkgObj); 
                               }  
                        }else if(bkgObj.Type__c !='Trial' && reqLeavObj.Sick_leave_start_Time__c == null){
                            bkgObj.Status__c='Canceled';
                            bkgObj.Cancellation_Reason__c= reqLeavObj.RecordTypeId==sickRecordTypeId ? 'Teacher MC':'Teacher Leave';
                            cancelBookingList.add(bkgObj);
                        }
                        if(bkgObj.Type__c=='Regular' && reqLeavObj.Sick_leave_start_Time__c != null){
                            system.debug('bkgObj.Start_Time__c'+bkgObj.Start_Time__c +'====>'+reqLeavObj.Sick_leave_start_Time__c );
                            if( (bkgObj.Start_Time__c>=reqLeavObj.Sick_leave_start_Time__c && reqLeavObj.Leave_Start_Date__c ==bkgObj.Booking_Date__c )
                               || reqLeavObj.Leave_Start_Date__c !=bkgObj.Booking_Date__c){
                                
                                // Added by nishi: 22-Jul-2020:Start: for ossia students booking will cancel then we added expiry date 180
                                // otherwise we added 120 days for other students
                                if(String.isNotBlank(bkgObj.Center__c) && 
                                String.isNotBlank(bkgObj.Center__r.Organisation__c) && 
                                String.isNotBlank(bkgObj.Center__r.Organisation__r.Name) && 
                                bkgObj.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){ 
                                    if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                                        bkgObj.Make_up_Expiry_Date__c=bkgObj.Booking_Date__c.addDays(Integer.valueOf((listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_Teacher__c)));
                                    }
                                }else{
                                    bkgObj.Make_up_Expiry_Date__c=bkgObj.Booking_Date__c.addDays(120);
                                }
                                // Added by nishi: 22-Jul-2020:end: for ossia students booking will cancel then we added expiry date 180
                                // otherwise we added 120 days for other students

                                string description='placeholder booking for cancelling '+ bkgObj.Student__r.Name +' booking';
                                Booking__c placIns= new Booking__c(Center__c=bkgObj.Center__c,RecordTypeId=lessonRecordType,
                                                                    Teacher_Account__c=bkgObj.Teacher_Account__r.Id,Type__c='Busy',Category__c='Placeholder',Remarks__c=description,
                                                                    Booking_Date__c=bkgObj.Booking_Date__c,Start_Time__c=bkgObj.Start_Time__c,End_Time__c=bkgObj.End_Time__c,Status__c='Scheduled');
                                placeholdeBooking.add(placIns);
                               }
                                system.debug('bkgObj'+bkgObj);
                        }else if(bkgObj.Type__c=='Regular' && reqLeavObj.Sick_leave_start_Time__c == null){
                            // Added by nishi: 22-Jul-2020:Start: for ossia students booking will cancel then we added expiry date 180
                                // otherwise we added 120 days for other students
                            if(String.isNotBlank(bkgObj.Center__c) && 
                                String.isNotBlank(bkgObj.Center__r.Organisation__c) && 
                                String.isNotBlank(bkgObj.Center__r.Organisation__r.Name) && 
                                bkgObj.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){ 
                                    if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                                        bkgObj.Make_up_Expiry_Date__c=bkgObj.Booking_Date__c.addDays(Integer.valueOf((listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_Teacher__c)));
                                    }
                            }else{
                                bkgObj.Make_up_Expiry_Date__c=bkgObj.Booking_Date__c.addDays(120);
                            }
                             // Added by nishi: 22-Jul-2020:End: for ossia students booking will cancel then we added expiry date 180
                            // otherwise we added 120 days for other students
                            string description='placeholder booking for cancelling '+ bkgObj.Student__r.Name +' booking';
                            Booking__c placIns= new Booking__c(Center__c=bkgObj.Center__c,RecordTypeId=lessonRecordType,
                                                               Teacher_Account__c=bkgObj.Teacher_Account__r.Id,Type__c='Busy',Category__c='Placeholder',Remarks__c=description,
                                                               Booking_Date__c=bkgObj.Booking_Date__c,Start_Time__c=bkgObj.Start_Time__c,End_Time__c=bkgObj.End_Time__c,Status__c='Scheduled');
                            placeholdeBooking.add(placIns);
                            system.debug('bkgObj'+bkgObj);
                        }
                        // upating Available Make up min to sum of total given Credit for Regular and Ad-hoc  
                        if((bkgObj.Type__c=='Regular' || bkgObj.Type__c=='Ad-hoc') && bkgObj.Duration__c != null && reqLeavObj.Sick_leave_start_Time__c != null){
                            if( (bkgObj.Start_Time__c>=reqLeavObj.Sick_leave_start_Time__c && reqLeavObj.Leave_Start_Date__c ==bkgObj.Booking_Date__c )
                               || reqLeavObj.Leave_Start_Date__c !=bkgObj.Booking_Date__c){
                                 bkgObj.Available_Make_up_Units__c= bkgObj.Duration__c;
                               }  
                        }else if( (bkgObj.Type__c=='Regular' || bkgObj.Type__c=='Ad-hoc') && bkgObj.Duration__c != null  && reqLeavObj.Sick_leave_start_Time__c == null){
                            bkgObj.Available_Make_up_Units__c= bkgObj.Duration__c;
                        }
                        if(bkgObj.Type__c =='Make-up' && bkgObj.Make_up_Utilize_Bookings__c != null && reqLeavObj.Sick_leave_start_Time__c != null){
                            if( (bkgObj.Start_Time__c>=reqLeavObj.Sick_leave_start_Time__c && reqLeavObj.Leave_Start_Date__c ==bkgObj.Booking_Date__c )
                               || reqLeavObj.Leave_Start_Date__c !=bkgObj.Booking_Date__c){
                                   for(String makeInstID : bkgObj.Make_up_Utilize_Bookings__c.split(';')){
                                       //Adding the Make up bkg id with the offered min
                                       if(bookingMakeUpMap.containsKey(makeInstID.split('-')[0])){
                                           Decimal offrMin=bookingMakeUpMap.get(makeInstID.split('-')[0]).Available_Make_up_Units__c + integer.valueOf(makeInstID.split('-')[1]);
                                           bookingMakeUpMap.put(makeInstID.split('-')[0], new Booking__c( Id = string.valueOf(makeInstID.split('-')[0]),Available_Make_up_Units__c = offrMin ));
                                       }else{
                                           bookingMakeUpMap.put(makeInstID.split('-')[0], new Booking__c( Id = string.valueOf(makeInstID.split('-')[0]),Available_Make_up_Units__c = integer.valueOf(makeInstID.split('-')[1]) ));  
                                       }
                                   }
                               }  
                        }else if( bkgObj.Type__c =='Make-up' && bkgObj.Make_up_Utilize_Bookings__c != null  && reqLeavObj.Sick_leave_start_Time__c == null){
                            for(String makeInstID : bkgObj.Make_up_Utilize_Bookings__c.split(';')){
                                //Adding the Make up bkg id with the offered min
                                if(bookingMakeUpMap.containsKey(makeInstID.split('-')[0])){
                                    Decimal offrMin=bookingMakeUpMap.get(makeInstID.split('-')[0]).Available_Make_up_Units__c + integer.valueOf(makeInstID.split('-')[1]);
                                    bookingMakeUpMap.put(makeInstID.split('-')[0], new Booking__c( Id = string.valueOf(makeInstID.split('-')[0]),Available_Make_up_Units__c = offrMin ));
                                }else{
                                    bookingMakeUpMap.put(makeInstID.split('-')[0], new Booking__c( Id = string.valueOf(makeInstID.split('-')[0]),Available_Make_up_Units__c = integer.valueOf(makeInstID.split('-')[1]) ));  
                                }
                            }
                        } 
                        
                          
                    }
                }
                
            } 
            system.debug('cancelBookingList'+cancelBookingList);
            if(bookingMakeUpMap.size()>0){
                update bookingMakeUpMap.values();
            }
            // inserting case for each booking except for trial
            if(casList.size()>0){
                insert casList;
            }
            // inserting the record of case when record type id is not sick leave
            if(notSickcasList.size()>0){
                insert notSickcasList;
            }
            
            // Inserting Makeup Booking list
            if(updateMakeupList.size()>0){
                update updateMakeupList;
            }
            // creating placeholder booking for the Regular  booking
            if(placeholdeBooking.size()>0){
                insert placeholdeBooking;
            }
            // calling future method to send mail on case to respective parent
            list<Id> Ids = new List<Id>();
            for(Case CasObj:casList){
                Ids.add(CasObj.Id);
            }
            list<Id> othrIdCase = new List<Id>();
            for(Case CasObj:notSickcasList){
                othrIdCase.add(CasObj.Id);
            }
            if(Ids.size()>0){
                sendCaseEmail(Ids,'Teacher MC'); 
            }
            system.debug('othrIdCase'+othrIdCase);
            if(othrIdCase.size()>0){
                sendCaseEmail(othrIdCase,'Teacher Leave');
            }
            // updating the Booking 
            if(cancelBookingList.size()>0){
                update cancelBookingList;
            }
            for(Leave_Request__c reqLeavObj:leaveReqList){
                Leave_Request__c leaveReObj = new Leave_Request__c();
                leaveReObj.Id=reqLeavObj.Id;
                leaveReObj.Calendar_Update_Process__c=true;
                leaveUpdateList.add(leaveReObj);
            }
            if(leaveUpdateList.size()>0){
                update leaveUpdateList;
            }
            for(Teacher_Working_Hour__c workInstance:[select Working_Day__c,Center_Name__c,Teacher_Name__c,Start_Time__c,End_Time__c from Teacher_Working_Hour__c  where  Break_Time__c=false and Active__c=true and Teacher_Name__c in:mapToTeacherDate.keySet()]){
                mapToworkinghour.put(workInstance.Teacher_Name__c +'/' + workInstance.Working_Day__c,workInstance.Start_Time__c + '/'+workInstance.End_Time__c + '/' + workInstance.Working_Day__c +'/'+workInstance.Center_Name__c);
            }
            
            // New Process For Fifth lesson Booking
            // here Creating placeholder for the Fifth Lesson Booking as per the status of CLosed and Open
            List<Booking__c> fifthPlaceholderBooking = new List<Booking__c>();
            List<Fifth_Lesson__c> fifthPlaceholderList = new List<Fifth_Lesson__c>();
            list<Fifth_Lesson__c> FifthLessonList= new list<Fifth_Lesson__c>([Select Id,Teacher_Account__r.Employee_Duty_Type__c,Student__r.Name,Parent__r.PersonContactId,End_Time__c,Center__c,Start_Time__c,Remarks__c,Center__r.Location__c,Parent__r.PersonEmail,Booking_Date__c,Teacher_Account__c from Fifth_Lesson__c where IsActive__c =true and Teacher_Account__c in:mapToTeacherDate.keySet() and Booking_Date__c>=today ]);
            for(Fifth_Lesson__c fifthObj:FifthLessonList){
                if(mapToTeacherDate.containsKey(fifthObj.Teacher_Account__c)){
                   Leave_Request__c leavReqObj =mapToTeacherDate.get(fifthObj.Teacher_Account__c);
                    if(fifthObj.Booking_Date__c >=leavReqObj.Leave_Start_Date__c && fifthObj.Booking_Date__c <=leavReqObj.Leave_End_Date__c){
                        // Creating placeholde and updating fifth lesson as per the Sick_leave_start_Time__c 
                        if(leavReqObj.Sick_leave_start_Time__c != null){
                            if( (fifthObj.Start_Time__c>=leavReqObj.Sick_leave_start_Time__c && leavReqObj.Leave_Start_Date__c ==fifthObj.Booking_Date__c )
                               || leavReqObj.Leave_Start_Date__c !=fifthObj.Booking_Date__c){
                                   Booking__c placIns= new Booking__c(Center__c=fifthObj.Center__c,RecordTypeId=lessonRecordType,
                                                                      Teacher_Account__c=fifthObj.Teacher_Account__c,Type__c='Busy',Category__c='Placeholder',Remarks__c='Placeholder booking for Cancelling 5th lesson of '+ fifthObj.Student__r.Name +'',
                                                                      Booking_Date__c=fifthObj.Booking_Date__c,Start_Time__c=fifthObj.Start_Time__c,End_Time__c=fifthObj.End_Time__c,Status__c='Scheduled'); 
                                   fifthPlaceholderBooking.add(placIns);
                                   Fifth_Lesson__c fObj = new Fifth_Lesson__c();
                                   fObj.Id=fifthObj.Id;
                                   fObj.Booking__r=placIns;
                                   fObj.Remarks__c='Placeholder booking for 5th lesson of '+ fifthObj.Student__r.Name +'';
                                   fObj.IsActive__c=false;
                                   fifthPlaceholderList.add(fObj);  
                               }  
                        }else if(leavReqObj.Sick_leave_start_Time__c == null){
                            Booking__c placIns= new Booking__c(Center__c=fifthObj.Center__c,RecordTypeId=lessonRecordType,
                                                               Teacher_Account__c=fifthObj.Teacher_Account__c,Type__c='Busy',Category__c='Placeholder',Remarks__c='Placeholder booking for Cancelling 5th lesson of '+ fifthObj.Student__r.Name +'',
                                                               Booking_Date__c=fifthObj.Booking_Date__c,Start_Time__c=fifthObj.Start_Time__c,End_Time__c=fifthObj.End_Time__c,Status__c='Scheduled'); 
                            fifthPlaceholderBooking.add(placIns);
                            Fifth_Lesson__c fObj = new Fifth_Lesson__c();
                            fObj.Id=fifthObj.Id;
                            fObj.Booking__r=placIns;
                            fObj.Remarks__c='Placeholder booking for 5th lesson of '+ fifthObj.Student__r.Name +'';
                            fObj.IsActive__c=false;
                            fifthPlaceholderList.add(fObj);   
                        }
                        // End
                    }
                }
            }
            if(fifthPlaceholderBooking.size()>0){
                insert fifthPlaceholderBooking;
            }
            
            if(fifthPlaceholderList.size()>0){
                for(Fifth_Lesson__c fifthObject:fifthPlaceholderList){
                    fifthObject.Booking__c=fifthObject.Booking__r.Id;
                }
                update fifthPlaceholderList;
            }
                
            // End    
            
            LeaveRequestHelperBatch helperBatch = new LeaveRequestHelperBatch();
            helperBatch.mapToworkinghourBatch=mapToworkinghour;
            helperBatch.mapToTeacherDateBatch=mapToTeacherDate;
            Database.executeBatch(helperBatch);
        }catch(Exception e){
            message='Exception';
            system.debug(e.getLineNumber()+'>>>'+e.getMessage());
            Database.rollback(sp);
        } 
    }
    
    @future
    private static void sendCaseEmail(list<Id> Ids,string leaveType){
        // Savepoint sp = Database.setSavepoint();
        string templateId ='';
        list<EmailTemplate> templateList= new list<EmailTemplate>();
        map<string,EmailTemplate> templatemap= new map<string,EmailTemplate>();
        // list<string> personEmailList = new list<string>();
        if(leaveType =='Teacher MC'){
            // template when teacher is on medical leave
            //templateList = [Select Id from EmailTemplate where name = 'Teacher MC' limit 1];  
            //added by nishi: 12-Oct-2020:start: for send email according to organisation
            for(EmailTemplate objEmailTemplate :[Select Id,name from EmailTemplate 
            where name = 'Teacher MC' 
            or name = 'Ossia_Teacher MC' 
            ]){
                templatemap.put(objEmailTemplate.name,objEmailTemplate);
            }
            //added by nishi: 12-Oct-2020:end: for send email according to organisation
        }else{
            // template when teacher is on Holiday
            //templateList = [Select Id from EmailTemplate where name = 'Teacher Leave' limit 1];
            //added by nishi: 12-Oct-2020:start: for send email according to organisation
            for(EmailTemplate objEmailTemplate :[Select Id,name from EmailTemplate 
            where name = 'Teacher Leave' 
            or name = 'Ossia_Teacher Leave' 
            ]){
                templatemap.put(objEmailTemplate.name,objEmailTemplate);
            }
            //added by nishi: 12-Oct-2020:end: for send email according to organisation
        }
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Case CasObject:[select Id,Booking__r.Type__c,Booking__r.Status__c,Booking__r.Start_Time__c,Booking__r.Parent__r.PersonContactId,Booking__r.Parent__r.personEmail,
                        Booking__r.Center__c,Booking__r.Center__r.Location__c,Booking__r.Teacher_Account__c,Booking__r.Center__r.Organisation__r.Name 
                        from Case where Id in:Ids]){
            system.debug('CasObject---'+CasObject.Booking__r.Parent__r.PersonEmail);
            if(String.isNotBlank(CasObject.Booking__r.Center__r.Organisation__r.Name) && String.isNotBlank(CasObject.Booking__r.Parent__r.PersonEmail) && (CasObject.Booking__r.Type__c =='Regular' || CasObject.Booking__r.Type__c =='Ad-hoc' ||  CasObject.Booking__r.Type__c =='Make-up' ) ){
                //personEmailList.add(CasObject.Booking__r.Parent__r.personEmail);
                //mail.setToAddresses(personEmailList);
                //added by nishi: 12-Oct-2020:start: for send email according to organisation
                if(templatemap != null && templatemap.size() > 0){
                    if(leaveType =='Teacher MC'){
                        if(CasObject.Booking__r.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                            if(templateMap.containsKey('Ossia_Teacher MC')){
                            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templatemap.get('Ossia_Teacher MC').id, CasObject.Booking__r.Parent__r.PersonContactId, CasObject.Id, CasObject.Booking__r.Center__r.Location__c);
                            emailList.add(mail); 
                            }
                        }else{
                            if(templateMap.containsKey('Teacher MC')){
                                Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templatemap.get('Teacher MC').id, CasObject.Booking__r.Parent__r.PersonContactId, CasObject.Id, CasObject.Booking__r.Center__r.Location__c);
                                emailList.add(mail); 
                            }
                        } 
                    }else{
                        if(CasObject.Booking__r.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                            if(templateMap.containsKey('Ossia_Teacher Leave')){
                                Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templatemap.get('Ossia_Teacher Leave').id, CasObject.Booking__r.Parent__r.PersonContactId, CasObject.Id, CasObject.Booking__r.Center__r.Location__c);
                                emailList.add(mail); 
                            }
                        }else{
                            if(templateMap.containsKey('Teacher Leave')){
                                Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templatemap.get('Teacher Leave').id, CasObject.Booking__r.Parent__r.PersonContactId, CasObject.Id, CasObject.Booking__r.Center__r.Location__c);
                                emailList.add(mail); 
                            }
                        } 
                    }
                }
                /*Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templateId, CasObject.Booking__r.Parent__r.PersonContactId, CasObject.Id, CasObject.Booking__r.Center__r.Location__c);
                emailList.add(mail);*/
                //added by nishi: 12-Oct-2020:end: for send email according to organisation
            }
        }
        system.debug('emailList'+emailList);
        if(!test.isRunningTest())
            for(Messaging.SendEmailResult results :Messaging.sendEmail(emailList,false)){
                if(!results.isSuccess())
                    system.debug(results.getErrors());
            }    
    }

}