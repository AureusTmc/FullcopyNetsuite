/*
 *  
 */
public class ConvertToMakeup implements IConvertFifthLesson{
    String lessonId, caseId, parentId;
    Boolean caseFlag;

    public ConvertToMakeup(String lessonId, String caseId, Boolean caseFlag) {
        this.lessonId = lessonId;
        this.caseId = caseId;
        this.caseFlag = caseFlag;
    }

    public String convertFifthLesson(){
        Boolean isSuccess = FALSE;
        String caseIdToReturn = '';
        List<Booking__c> makeupList = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessons = new List<Fifth_Lesson__c>();
        if(String.isNotBlank(lessonId)){
            fifthLessons = AureusCalendarControllerHelper.fetchFifthLessson(new Set<String>{lessonId});
            if(fifthLessons.size() > 0 && fifthLessons[0].parent__r.Available_Make_up_Units__c >= fifthLessons[0].duration__c){
                makeupList = AureusCalendarControllerHelper.createBookingFromFifthLesson(fifthLessons, 'makeup');    
            }
            
        }
        if(makeupList.size() > 0){
            insert makeupList;
            parentId = makeupList[0].parent__c;
            if(String.isNotBlank(parentId)){
                AureusCalendarController.deductMakeupHours(makeupList, parentId);
                isSuccess = TRUE;
            }
            
        }

        if(isSuccess){
            Fifth_Lesson__c lessonObj = new Fifth_Lesson__c();
            lessonObj.Id = lessonId;
            lessonObj.isActive__c = FALSE;
            lessonObj.Booking__c = makeupList[0].Id;
            update lessonObj;
            if(caseFlag){
                Case caseObj = AureusCalendarControllerHelper.createCase(caseId, makeupList[0].Id, 'Make-Up');
                if(caseObj != NULL && String.isNotBlank(caseObj.id)){
                    caseIdToReturn = caseObj.Id;
                }
            }else{
                caseIdToReturn = makeupList[0].Id;
            }
                
        }
        return caseIdToReturn;
    }

}