public without Sharing class FifthLessonController {
   @RemoteAction
   Public Static AureusCalendarController.EventDetails fetchLessonDetails(String lessonId){
       List<Fifth_Lesson__c> fifthLessonList = new List<Fifth_Lesson__c>();
       AureusCalendarController.EventDetails eventDetail = new AureusCalendarController.EventDetails();
       if(String.isNotBlank(lessonId)){
            fifthLessonList = AureusCalendarControllerHelper.fetchFifthLessson(new Set<String>{lessonId});
            if(fifthLessonList.size() > 0){
                DateTime lessonDate;
                lessonDate = DateTime.newInstance(fifthLessonList[0].Booking_Date__c, fifthLessonList[0].Start_Time__c);
                eventDetail.Id = fifthLessonList[0].Id;
                eventDetail.name = fifthLessonList[0].Name;
                eventDetail.staffMember = fifthLessonList[0].Teacher_Account__r.FirstName + ' ' + fifthLessonList[0].Teacher_Account__r.LastName;
                eventDetail.staffMemberId = fifthLessonList[0].Teacher_Account__c;
                eventDetail.centerId = fifthLessonList[0].Center__c;
                eventDetail.centerName = fifthLessonList[0].Center__r.Name;
                eventDetail.dateAndTime = lessonDate.format('EEE, MMM dd YYYY');
                eventDetail.endDateTime = lessonDate.format('h:mm a');
                eventDetail.duration = fifthLessonList[0].Duration__c;
                eventDetail.parentFirstName = fifthLessonList[0].Parent__r.FirstName + ' ' + fifthLessonList[0].Parent__r.LastName;
                eventDetail.parentMobile = fifthLessonList[0].Parent__r.PersonMobilePhone;
                eventDetail.parentEmail = fifthLessonList[0].Parent__r.PersonEmail;
                eventDetail.studentFirstName = fifthLessonList[0].Student__r.FirstName + ' ' + fifthLessonList[0].Student__r.LastName;
                eventDetail.type = 'Fifth Lesson';
                eventDetail.studentId = fifthLessonList[0].Student__c;
                eventDetail.parentId = fifthLessonList[0].Parent__c;
                eventDetail.newPackage = fifthLessonList[0].Package__c; 
                eventDetail.newPackageName = fifthLessonList[0].Package__r.Name; 
                eventDetail.amm = fifthLessonList[0].Parent__r.Available_Make_up_Units__c;
            }
            
       }
       return eventDetail;
   }

   
   /*
    *   This Method Will Create the Placeholder with the same as 
    *   5th Lesson. And Delete the 5th Lesson Record through interface
    */
   @RemoteAction
   Public Static String bookingConvert(String lessonId, String caseId, String type, Boolean flag){
        String caseIdToReturn = '';
        IConvertFifthLesson convertTypeObj;
        if(type == 'placeholder'){
            convertTypeObj = new ConvertToPlaceholder(lessonId, caseId);
        }else if(type == 'makeup'){
            convertTypeObj = new ConvertToMakeup(lessonId, caseId, flag);
        }else if(type == 'adhoc'){
            convertTypeObj = new ConvertToAdhoc(lessonId, caseId, flag);
        }
        caseIdToReturn = convertTypeObj.convertFifthLesson();
        return caseIdToReturn;
   }
}