/*
 *  
 */
public class ConvertToPlaceholder implements IConvertFifthLesson{
    String lessonId, caseId;
     
    public ConvertToPlaceholder(String lessonId, String caseId) {
        this.lessonId = lessonId;
        this.caseId = caseId;
    }

    public String convertFifthLesson(){
        Boolean isSuccess = FALSE;
        String bookingIdToReturn = '';
        List<Booking__c> placeholderList = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessons = new List<Fifth_Lesson__c>();
        if(String.isNotBlank(lessonId)){
            fifthLessons = AureusCalendarControllerHelper.fetchFifthLessson(new Set<String>{lessonId});
            placeholderList = AureusCalendarControllerHelper.createBookingFromFifthLesson(fifthLessons, 'placeholder');
        }
        if(placeholderList.size() > 0){
            insert placeholderList;
            bookingIdToReturn = placeholderList[0].Id;
            isSuccess = TRUE;
        }
        if(isSuccess){
            Fifth_Lesson__c lessonObj = new Fifth_Lesson__c();
            lessonObj.Id = lessonId;
            lessonObj.isActive__c = FALSE;
            lessonObj.Booking__c = placeholderList[0].Id;
            update lessonObj;
            /*Case caseObj = AureusCalendarControllerHelper.createCase(caseId, placeholderList[0].Id, 'Busy');
            if(caseObj != NULL && String.isNotBlank(caseObj.id)){
                 caseIdToReturn = caseObj.Id;
            }*/   
        }
        return bookingIdToReturn;
    }

}