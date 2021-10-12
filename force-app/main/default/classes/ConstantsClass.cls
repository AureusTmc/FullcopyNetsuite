public class ConstantsClass {
    
    public static String centerRecTypeName  = 'Centre';
    public static String parentRecTypeName  = 'Parent';
    public static String studentRecTypeName = 'Student';
    public static String teacherRecTypeName = 'Teacher';
    public static String customerRecTypeName= 'Customer';
     // Added by jatin: 20-jan-2020:start: related to Employee
    public static string employeeRecTypeName = 'Employee'; 
    public static string employeeJobTitle = 'Sales Executive';
    public static string employeeConfirmStatus = 'Confirm';
    public static string employeeProbationStatus = 'Probation';
     // Added by jatin: 20-jan-2020:END: related to Employee

    //Opportunity Recordtype
    public static String enrolmentRecTypeName = 'Enrolment';
    
    public static String mapDefAdd = '583 Orchard Road 238884 Singapore';
    public static String mapDefAddHK = 'Shop No. G9A-9C, G/F, Island Resort Mall, 28 Siu Sai Wan, Siu Sai Wan Hong Kong';
    public static Integer afternoonSlot = 12;
    public static Integer defMinutes = 15;
    
    public static String oppClosedWon       = 'Closed Won';
    public static String activeStatus       = 'Active';
    public static String trialStatus        = 'Trial';
    public static String requestedSubStatus = 'Requested';
    public static String paidStatus         = 'Paid';   
    public static String dueStatus          = 'Due';   
    public static String successStatus      = 'Success';
    public static String enroledStatus      = 'Enrolled';
    public static String scheduledStatus    = 'Scheduled';
    public static String pendingStatus      = 'Pending';
    public static String payMonthlyFrequency= 'Monthly';
    public static String pkgOneTimeType     = 'One-time';
    public static String pkgWeeklyType      = 'Weekly';
    
    public static String bookTypeRegular    = 'Regular';
    
    public static Integer defaultMinutesDiffinSlot = 15;
    
    //By Ravi
    //  Related to case 
    public static String ClosedStatus      = 'Closed';
    public static String NewStatus         = 'New';
    public static String caseServiceEnqRecTypeName = 'Service Request';
    public static String InstrumentRentalEnquiryRecordType ='Instrument Rental Enquiry';// added by nishi: 28-Apr-2021: for piano rental enquiry recordtype
    
    public static String cancelType = 'Cancel';
    public static String casePendingStatus  = 'Pending';
    public static String caseOpenStatus = 'Open';
    public static String rescheduleType = 'Reschedule';
    public static String caseMakeupType = 'Make-Up';
 	
    public static String caseAutomationOrigin = 'Automation';
    // Related to Task
    public static String OpenStatus ='Open';
    public static String PendingEnrolment='Pending Enrolment';
    // By Ravi
    public static String Online ='Online';
    public static String InCentre='In Centre';
     //Default invoice line item descriptin 
    public static String pkgPrgFeesDes  = 'Program Fees';
    public static String pkgRegFeesDes  = 'Registration Fees';
    public static String pkgDepFeesDes  = 'Deposit Fees';
    //@juneid 18 Aug,2020, facility Fees
    public static string facilityFee = 'Facility Fees';
    
    public static String defAttSignName = 'Signature.png';
    public static String prePayAttSignName = 'PrePaySignature.png';
    //Enrolment page GST percentage
    public static Integer defGST = 7;
    
    public static Integer addInvoiceDueDays = 0;
    public static Integer subNextBillingDay = 1;
    
    public static String busyBookingType   = 'Busy';
    public static String studioBookingType = 'Studio';
    public static List<string> modeOfPayments = new List<string>{'Card','Cheque','Cash'};
    
    public static String currencyCode= 'SGD';
    
    //Edited by jatin
    /*
        Related to Booking
    */
    public static string recordTypeFacility = 'Facility';
    public static string recordTypeLesson = 'Lesson';
    public static string statusCanceled = 'Canceled';
    public static string recordTypeCustomer = 'Customer';
    public static string recordTypeCenter = 'Centre'; 
    public static string typeBusy = 'Busy';
    public static string typeTrial = 'Trial';
    public static string typeGroup = 'Group';   // added by Zakir : Add Type Group in the site .
    public static string typeAdhocGroup = 'Group Adhoc'; // added by nishi: 2-Nov-2020: for group lesson adhoc package type
    public static string typeAdhoc = 'Ad-hoc';
    public static string typeMakeup = 'Make-up';
    public static string typePianoViewing = 'Piano Viewing'; //add by jatin: 20-jan-2020 : for show piano viewing type bookings
    public static string statusScheduled = 'Scheduled';
    public static string statusReScheduled = 'Re-scheduled';
    public static string statusPending = 'Pending';
    public static string typeRegular = 'Regular';
    public static string typeAudition = 'Audition';
    public static string statusNoshow = 'No-show';
    public static string statusCompleted = 'Completed';
    public static string eventTextColor = '#000';
    public static string resourceStatusAvailable = 'Available';
    public static string standardResourceType    = 'Standard';
    public static string notAvailableWorkingHoursColor = '#808080';
    public static string availableWorkingHoursColor = '#fff';
    public static string calendarMaxTime = '22:00:00';
    public static string calendarMinTime = '07:00:00';
    public static string teacherRecordType = 'Teacher'; 
    public static string teacherWorkingStatus = 'Working';
    public static Set<String> teacherPartTimeEngagementStatus = new Set<string> {'Commission'/*,'Part-Time'*/}; // added by nishi : 18-Sep-2020: for manage Commission type teacher in ossia organisation
    public static string teacherProfileName = '%Profile Image%';
    public static string makeupReasonOther = 'Other';
    public static string makeupAdminException = 'Admin/CM Exception';
    public static string pakageTypeMakeup = 'Makeup';
    public static String enrollStageAttended = 'Attended';
    public static String enrollStageLost     = 'Lost';
    public static String cstmMetaDataStripe  = 'Stripe';
    public static String categoryLunch = 'Lunch';
    public static String categoryTravel = 'Travel';
    public static String bookingCategoryPlaceHolder = 'Placeholder';
    public static String bookingCategory5thLesson = '5th Lesson'; 
    public Static String packageTypeGroup = 'Group';
    public Static Integer periodOfClassesInMonths = 12;
    Public static String blockStatus = 'Blocked';
    Public Static String leaveCategory = 'Leave';
    Public Static String holidayCategory = 'Holiday';
    
    public static String enrollmentProcessPendingStatus = 'Pending';
    public static String enrollmentProcessCompletedStatus = 'Completed';
    // Added by Jaitn :Start: 30-Dec-2019: for Instrument Business Stages requiremnt new Record type Created  'Instrument Rental'
    public static String enrollmentInstrumentRecTypeName = 'Instrument Rental';
    public static String enrollmentLessonRecTypeName = 'Lesson';
    // Added by Jaitn : End : 30-Dec-2019: for Instrument Business Stages requiremnt new Record type Created  'Instrument Rental'

    // Added by Jaitn :Start: 28-Jan-2020: for Instrument Business Stages requiremnt new type and stage Created  
    public static String enrollmentTypeInstrument = 'Instrument';
    public static String enrollmentPianoRentalActiveStage = 'Piano Rental Active';
    public static String enrollmentPianoViewingBookedStage = 'Piano Viewing Booked';
    public static String enrollmentPianoViewingCompletedStage = 'Piano Viewing Completed';
    public static String enrollmentPianoTerminationInProgressStage = 'Piano Termination In-Progress';
    public static String enrollmentPianoRentalTerminatedStage = 'Piano Rental Terminated';
    public static String enrollmentPianoSoldStage = 'Piano Sold';
    public static String enrollmentNotInterestedStage = 'Not Interested';

    // Added by Jaitn : End : 28-Jan-2020: for Instrument Business Stages requiremnt new type and stage Created  
 // Added by Jaitn :Start: 13-Feb-2020: for Camp class requiremnt new type   
    public static String enrollmentTypeCamp = 'Camp';
    public static String bookingRecordsTypeCampLesson = 'Camp Lesson'; // 12-Feb-2020: jatin:for camp Booking records type
    public static string campActiveStatus='Active';
    public static string campCancelledStatus='Cancelled';// 19-Feb-2020: jatin : for cancel status in  camp class
    public static string campDaysActiveStatus='Active';
    public static string campTeacherActiveStatus='Active';// 19-Feb-2020:jatin: for  camp teachers InActive status
    public static string campTeacherInActiveStatus='InActive'; // 19-Feb-2020:jatin: for  camp teachers InActive status
    public static String bookingCategoryCamp = 'Camp'; // 26-Feb-2020:for manage Camp Category
 // Added by Jaitn :Start: 13-Feb-2020: for Camp class requiremnt new type 
    

    public static String enrollmentProcessUpgradeType = 'Upgrade';
    public static String enrollmentProcessDowngradeType = 'Downgrade';
    public static String enrollmentProcessCancelType = 'Cancellation';
    public static String enrollmentStageCancelled = 'Cancelled';
    public static String enrollmentProcessChanged = 'Enrolment Change';
    public static String enrollmentProcessChangedCenter = 'Centre Change'; // added by nishi: 28-Aug-2020: for added new process value in Package_Process_Type__c field
    //Enrolment mapping values with Case and Opportunity for the Sales process
    //'Trial Lost'   => 'Lost',  Added by Rajesh on (17-06-2020), need to build this functionality from enrolment as per discussion with Ashish or Alex
    public static Map<String, String> salesProcessStatusMap = new Map<String, String>{'Trial Requested'  => 'Trial Requested',
                                                                                      'Trial Booked'    => 'Trial Booked',
                                                                                      'Trial Attended'  => 'Trial Attended',
                                                                                      'Trial Cancelled' => 'Trial Cancelled',
                                                                                      'Trial No-Show'   => 'Trial No Show',
        																			  'Trial Transferred'   => 'Transferred',
                                                                                      'Regular Enrolled'=> 'Enrolled',
        																			  'Trial Lost'   => 'Lost',
                                                                                      // 28-Apr-2021:added by Nishi: need to build this functionality from enrolment as per discussion with Rajesh or Alex 
                                                                                      'Piano Viewing Booked' => 'Piano Viewing Booked',
                                                                                      'Piano Viewing Completed' =>'Piano Viewing Completed',
                                                                                      'Piano Rental Active' =>'Piano Rental Active',
                                                                                      'Piano Termination In-Progress' =>'Piano Termination-In Progress',
                                                                                      'Piano Rental Terminated'=>'Piano Rental Terminated',
                                                                                      'Piano Sold'=>'Piano Sold',
                                                                                      'Not Interested'=>'Not Interested'
                                                                                    };
    public static String trialLost = 'Trial Lost';  
    public static String caseLost = 'Lost'; 
    public static String caseSalesEnqRecTypeName = 'Sales Enquiry';
    
    public static String statusInActive = 'In Active';    
    
    public static String enrolmentProcessUpgradeTypeForCase = 'Advancement';
    public static String enrolmentProcessWithdrawalTypeForCase = 'Withdrawal';
    
    //payment record constants
    public static String creditNoteRecType = 'Payment As Discount';
    public static String paymentTransactionRecType = 'Payment Transaction';
    public static String paymentPendingStatus = 'Pending';
    public static String paymentSuccessStatus = 'Success';

    // Credit Memo Constants :nishi: 16-Sep-2020
    public static String creditMemoPendingStatus = 'Pending';
    public static String creditMemoSuccessStatus = 'Success';

    //Activated center Name
    //Enrolment mapping values with Case and Opportunity for the Sales process
    public static Set<String> activatedCenNames = new Set<String>{'Aureus 112 Katong','Aureus Suntec',
                                                                  'Aureus Eastpoint Mall','Aureus Northpoint',
                                                                  'Aureus @ Home','Aureus Rochester',
                                                                  'Aureus United Square','Aureus Westgate',
                                                                  'Aureus AMK Hub','Aureus Forum'};
        
    public static String amcClubMember = 'American Club';
    public static String enrolRegularStatus = 'Regular';
    // jatin : 26-dec- 2019: for add status enrolment
    public static String enrolGroupType = 'Group';
    public static String paymentAsDepositRecordType = 'Payment As Deposit';
    public static String paymentAsCredit='Payment As Credit';
    public static String prePaymentType = 'Prepayment';
    public static String PromoTypePayment = 'Promo';
    
    //Updated by rajesh, 9th Sept 2019. change default consolidated invoice Centre from 'Aureus Pianos' to 'Aureus Forum'
    public static String centreNameForAmcClubInvoice = 'Aureus Forum'; 
    
    public static String voidInvoiceStatus = 'Void';
    public static String cancelledInvoiceStatus = 'Cancelled';
    public static String invoiceTypeAdhoc = 'Adhoc';
    public static String cardModeType = 'Card';
    public static String groupTypeBooking = 'Group Class';
    public static String groupBookingRecordType = 'Group Class';
    public static String groupLessonTypeBooking = 'Group Lesson';
    public static String groupLessonBookingRecordType = 'Group Lesson';
    public static String payoutStatusUnprocessed = 'Unprocessed';
    public static String adhocPackageType = 'Adhoc';
    public static String approvedTeacherLeave = 'Approved';
    public static String recurringInvoiceType = 'Recurring';
    public static String paymentVoid = 'Void';
    
    //by uzair 14/01/2020
    public static Decimal chargerate = 10;
    public static Set<String> excludedPayoutItemsbonus = new Set<string> {'Bonus (AW)','Bonus (OW)','Bonus (NON-CPF)','Referral Bonus','NS Make-up Pay'}; // added by uzair : 18-Nov-2020
    public static String enrolWaitingStatus = 'Waiting';
}