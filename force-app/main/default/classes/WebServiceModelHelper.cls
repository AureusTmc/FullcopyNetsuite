public class WebServiceModelHelper{
    //---------------------Modal Classes ----------------------//
    public class MakeupPackageSelection{
        public list<packages> packages;
        public Map<string,List<instrument>> instrumentsWithTeacher;
        public MakeupPackageSelection(){
            instrumentsWithTeacher =new Map<string,List<instrument>>();
            packages = new  list<packages>();
        }
    }
    
    public class instrument{
        public String teachername;
        public String teacherId; 
        public instrument(){
            teachername = null;
            teacherId = null; 
        }
    }
    public class TeacherDetails{
        public List<instrument> teachers;
        public TeacherDetails(){
            teachers = new  List<instrument>();
        }
    }
    public class packages{
        public String packageId;
        public String packageName;
        public Integer duration;
        public packages(){
            packageId = null;
            packageName = null;
            duration = null;
        }
    }
    public class LessonResult{
        public List<lesson> lessons;
        public LessonResult(){
            lessons = new List<lesson>();
        }
    }
    public Class lesson{
        public String lessonName;
        public String lessonId;
        public lesson(){
            lessonName = null;
            lessonId = null;
        }
    }
    public class PickListOption{
        public String apiName;
        public String label;
        public PickListOption(){
            apiName = null;
            label = null;
        }
    }
    
    /* public class EventModal{
public string title;
public string image;
public string Description;
public string url;
public EventModal(){
title = null;
image = null;
Description = null;
url = null;
}
}*/
    public class student{
        public string schoolName;
        public string firstName;
        public string lastName;
        public string gender;
        public date Birthdate;
        public String learningStyle;
        public String studentId;
        public student(){
            schoolName = null;
            firstName = null;
            lastName = null;
            gender = null;
            Birthdate = null;
            learningStyle = null;
            studentId = null;
        }
    }
    public class HomePageModal {
        public string parentId;
        public string name;
        public string firstName;
        public string lastName;
        public string gender;
        public string email;
        public String phone;
        public string nationality;
        public String street;
        public String city;
        public String country;
        public String postal_Code; 
        public String availableMakeupUnits ;
        public String cardNumber;
        public String cardType;
        public String expiration;
        public Date nextBillingDate;
        public Boolean isInvoiceDue ;
        public Boolean isAmericanClubMember;
        public list<event> events;
        public list<student> students;
        public Boolean invoicePaidNotification;
        public Boolean bookingRemindedNotification ;
        public string profilePictureUrl;
        public string centreCurrency;
        // added 21-nov-2019 for show fifth booking url
        public string fifthBookingFaqUrl;
        // public list<bookings> bookings;
        public list<Enrollments> enrolments;
        
        public HomePageModal () {
            events = new list<event>();
            students = new list<student>();
            // bookings = new list<bookings>();
            enrolments= new list<Enrollments>();
            parentId = null;
            name = null;
            firstName = null;
            lastName = null;
            gender = null;
            email = null;
            phone = null;
            nationality = null;
            street = null;
            city = null;
            country = null;
            postal_Code = null; 
            availableMakeupUnits  = null;
            cardNumber = null;
            cardType = null;
            expiration = null;
            nextBillingDate = null;
            isInvoiceDue  = null;
            isAmericanClubMember = null;
            // added 21-nov-2019 for show fifth booking url
            fifthBookingFaqUrl = null;
            invoicePaidNotification = null;
            bookingRemindedNotification  = null;
            profilePictureUrl = null;
            centreCurrency = null;
        }
        
    }
    public class event {
        Public String description;
        Public String sr_No;
        Public String imageURL;
        Public String title;
        Public String webURL;
        public event(){
            description= null;
            sr_No= null;
            imageURL= null;
            title= null;
            webURL= null;
        }
    }
    public class CasesResult{
        Public List<Cases> cases;
        public CasesResult(){
            cases = new List<Cases>();
        }
    }
    public class BookingResult{
        Public List<Bookings> bookings;
        public BookingResult(){
            bookings= new List<Bookings>();
        }
    }
    public class Cases {
        Public String caseId;
        Public String subject;
        Public String description;
        Public String studentId;
        Public String studentName;
        Public String type;
        Public String parentId;
        Public String status;
        Public String caseNumber;
        Public List<caseComment> caseComments;
        public dateTime createdDate;
        public Cases(){
            caseId= null;
            subject= null;
            description= null;
            studentId= null;
            studentName= null;
            type= null;
            parentId= null;
            status= null;
            caseNumber= null;
            List<caseComment> caseComments = new List<caseComment>();
            createdDate= null;
        }
    }
    public class CaseComment{
        public string commentId;
        public string caseId;
        public string comment;
        public dateTime commentDate;
        public string Owner;
        public CaseComment(){
            commentId= null;
            caseId= null;
            comment= null;
            commentDate= null;
            Owner= null;
        }
        
    }
    public class EnrollmentsResult{
        public List<Enrollments> enrollments;
        public EnrollmentsResult(){
            enrollments = new List<Enrollments>();
        }
    } 
    public class Enrollments{
        Public String id;
        Public String studentName;
        Public String studentId;
        public String instrument;
        Public String duration;
        public String lessonDay;
        Public String lessonType;
        Public Time regularTime;
        public String teacherName;
        public String teacherId;
        public String status;
        public String location;
        public String centerId;
        
        //package details 
        Public String packageName;
        Public String packageId;
        Public String packagePrice;
        Public Date NextBillDate;
        public String programId;
        public String packageType;
        public String lessonTypeNew;
        public String lessonPasscode;
        public String lessonOnlineURL;
        //Booking detalis
        Public List<Bookings> bookings;
        public Enrollments(){
            id= null;
            studentName= null;
            studentId= null;
            instrument= null;
            duration= null;
            lessonDay= null;
            lessonType= null;
            regularTime= null;
            teacherName= null;
            teacherId= null;
            status= null;
            location= null;
            centerId= null;
            
            //package details 
            packageName= null;
            packageId= null;
            packagePrice= null;
            NextBillDate= null;
            programId= null;
            packageType = null;
            lessonTypeNew = null;
            //Booking detalis
            bookings= new List<Bookings>();
        }
    }
    public class Bookings{
        Public String bookingId;
        Public String studentName;
        Public String studentId;
        Public Date date_c;
        Public String weekday; 
        Public String packageName;
        Public String duration;
        Public Time   time_c;  
        Public String center;
        public String teacherName;
        Public String centerId;
        public String teacherId;
        public String instrument;
        public String enrollmentId;
        public String status ;
        public Boolean rescheduled; 
        public String type;
        public String cancellationReason ;
        Public String availableMakeupMin ;
        Public Date expiryDate;
        public String packageType;
        public Boolean isFifthBooking;
        public Double unitFee;
        public decimal gst;
        public String lessonTypeNew;
        public String lessonPasscode;
        public String lessonOnlineURL;
        public Bookings(){
            bookingId = null;
            studentName = null;
            studentId = null;
            date_c = null;
            weekday = null; 
            packageName = null;
            duration = null;
            time_c = null;  
            center = null;
            teacherName = null;
            centerId = null;
            teacherId = null;
            instrument = null;
            enrollmentId = null;
            status  = null;
            rescheduled = null; 
            type = null;
            cancellationReason  = null;
            availableMakeupMin  = null;
            expiryDate = null;
            packageType = null;
            isFifthBooking = false;
            unitFee= null;
            gst = null;
            lessonTypeNew = null;
            lessonPasscode = null;
            lessonOnlineURL = null;
        }
        
    }
    public class InvoiceResult {
        public List<invoice> invoices;
        public InvoiceResult(){
            invoices = new List<invoice>();
        }
    }
    public class invoice{
        public String invoiceId; 
        public Date invoiceDate;
        public Date dueDate;
        public Decimal balanceAmount;
        public String status ;
        public Decimal grossTotal;
        public Decimal subTotal; 
        public Decimal gstTax;
        public Decimal gstTaxAmount;
        public Decimal discountAmount;
        public Decimal Deposit;
        public Decimal totalAmount;
        public String pdfUrl;
        public String pdfDownloadUrl;
        public String invoiceNumber;
        public String cardNumber;
        public String cardType;
        public List<payment> payments;
        public invoice(){
            invoiceId= null; 
            invoiceDate= null;
            dueDate= null;
            balanceAmount= null;
            status = null;
            grossTotal= null;
            subTotal= null; 
            gstTax= null;
            gstTaxAmount= null;
            discountAmount= null;
            Deposit= null;
            totalAmount= null;
            pdfUrl= null;
            pdfDownloadUrl= null;
            invoiceNumber= null;
            cardNumber= null;
            cardType= null;
            payments= new List<payment>();
        }
        
    } 
    public class payment{
        public Date paymentDate;
        public decimal amount;
        public String method;
        public payment(){
            paymentDate = null;
            amount = null;
            method = null;
        }
    }
    
    public class WorkingHours{
        Public String weekDay;
        Public String centre;
        Public List<TeacherSlot> timeSlots; 
        public WorkingHours(){
            weekDay = null;
            centre = null;
            timeSlots =  new list<TeacherSlot>();
        }
    }
    public class TeacherSlot{
        Public String teacherId;
        Public String teacherName;
        Public List<String> timeslots;
        public TeacherSlot(){
            teacherId = null;
            teacherName = null;
            timeslots = new List<String>();
        }
    }
    
    public class StripeCharge{
        public String id {get;set;} 
        public String object_z{get;set;}
        public Integer account_balance {get;set;} 
        public String address {get;set;}
        public Integer balance {get;set;} 
        public Integer created {get;set;}  
        public String default_source {get;set;} 
        public Boolean delinquent {get;set;} 
        public String description {get;set;} 
        public integer discount {get;set;}
        Public StripeError error{get;set;}
        public String email {get;set;} 
        public String invoice_prefix {get;set;} 
        public Invoice_settings invoice_settings {get;set;} 
        public Boolean livemode {get;set;} 
        public Metadata metadata {get;set;} 
        public string name {get;set;} 
        public string phone {get;set;} 
        public List<Preferred_locales> preferred_locales {get;set;} 
        public string shipping {get;set;} 
        public Sources sources {get;set;} 
        public Subscriptions subscriptions {get;set;} 
        public String tax_exempt {get;set;} 
        public Subscriptions tax_ids {get;set;} 
        public String tax_info {get;set;} 
        public string  tax_info_verification {get;set;} 
        public Integer statusCode{get;set;}
        public StripeCharge(){
            id = null; 
            object_z = null;
            account_balance = null; 
            address = null;
            balance = null; 
            created = null;  
            default_source = null; 
            delinquent = null; 
            description = null; 
            discount = null;
            error = new StripeError();
            email = null; 
            invoice_prefix = null; 
            invoice_settings = new Invoice_settings();
            livemode = null; 
            metadata = new Metadata();
            name = null; 
            phone = null; 
            preferred_locales = new List<Preferred_locales>();
            shipping = null; 
            sources = new Sources(); 
            subscriptions = new Subscriptions();
            tax_exempt = null; 
            tax_ids = new Subscriptions();
            tax_info = null; 
            tax_info_verification = null; 
            statusCode =null;
        }
    }
    
    public class Invoice_settings {
        public string custom_fields {get;set;} 
        public string default_payment_method {get;set;} 
        public string  footer {get;set;} 
        public Invoice_settings(){
            custom_fields = null;
            default_payment_method = null;
            footer = null;
        }
    }
    public class Metadata {
        public String Name {get;set;} 
        public Metadata(){
            Name = null;
        }
    }
    public class Preferred_locales {
        public Preferred_locales(){
            
        }
    }
    Public class StripeError {
        public String charge{get;set;}  //@28-02-2019 store chargeId when we make charges By Sanjay bhati
        Public String stripeType{get;set;} 
        Public String param{get;set;} 
        Public String message{get;set;} 
        Public String code{get;set;} 
        public String decline_code{get;set;} 
        public StripeError(){
            charge= null;  
            stripeType= null; 
            param= null; 
            message= null; 
            code= null; 
            decline_code= null; 
        }
    }
    public class Sources {
        public String object_z {get;set;} // in json: object
        public List<Data> data {get;set;} 
        public Boolean has_more {get;set;} 
        public Integer total_count {get;set;} 
        public String url {get;set;} 
        public Sources(){
            object_z = null;
            data = new List<Data>();
            has_more = null;
            total_count = null;
            url = null;
        }       
    }
    public class Data {
        public String id {get;set;} 
        public String object_z {get;set;} // in json: object
        public decimal amount {get;set;} 
        public Card card {get;set;} 
        public String client_secret {get;set;} 
        public Integer created {get;set;} 
        public decimal currency_z {get;set;}
        public string default_source{get;set;} 
        public String customer {get;set;} 
        public String flow {get;set;} 
        public Boolean livemode {get;set;} 
        public Metadata metadata {get;set;} 
        public Owner owner {get;set;} 
        public string statement_descriptor {get;set;} 
        public String status {get;set;} 
        public String type {get;set;} // in json: type
        public String usage {get;set;} 
        public String address_city {get;set;} 
        public String address_country {get;set;} 
        public String address_line1 {get;set;} 
        public String address_line1_check {get;set;} 
        public String address_line2 {get;set;} 
        public String address_state {get;set;} 
        public String address_zip {get;set;} 
        public String address_zip_check {get;set;} 
        public String brand {get;set;} 
        public String country {get;set;} 
        public String cvc_check {get;set;} 
        public String dynamic_last4 {get;set;} 
        public Integer exp_month {get;set;} 
        public Integer exp_year {get;set;} 
        public String fingerprint {get;set;} 
        public String funding {get;set;} 
        public String last4 {get;set;} 
        public String name {get;set;} 
        public String tokenization_method {get;set;} 
        public Data(){
            id = null;
            object_z = null;// in json: object
            amount = null;
            card = new Card();
            client_secret = null;
            created = null;
            currency_z = null;
            default_source= null;
            customer = null;
            flow = null;
            livemode = null;
            metadata = new Metadata();
            owner = new owner();
            statement_descriptor = null;
            status = null;
            type = null;// in json: type
            usage = null;
            address_city = null;
            address_country = null;
            address_line1 = null;
            address_line1_check = null;
            address_line2 = null;
            address_state = null;
            address_zip = null;
            address_zip_check = null;
            brand = null;
            country = null;
            cvc_check = null;
            dynamic_last4 = null;
            exp_month = null;
            exp_year = null;
            fingerprint = null;
            funding = null;
            last4 = null;
            name = null;
            tokenization_method = null;
        }
    }
    
    public class Card {
        public Integer exp_month {get;set;} 
        public Integer exp_year {get;set;} 
        public String last4 {get;set;} 
        public String country {get;set;} 
        public String brand {get;set;} 
        public String cvc_check {get;set;} 
        public String funding {get;set;} 
        public String fingerprint {get;set;} 
        public String three_d_secure {get;set;} 
        public String  name{get;set;} 
        public String address_line1_check {get;set;} 
        public String address_zip_check {get;set;} 
        public String tokenization_method {get;set;} 
        public String dynamic_last4 {get;set;} 
        public Card(){
            exp_month = null;
            exp_year = null;
            last4 = null;
            country = null;
            brand = null;
            cvc_check = null;
            funding = null;
            fingerprint = null;
            three_d_secure = null;
            name = null;
            address_line1_check = null;
            address_zip_check = null;
            tokenization_method = null;
            dynamic_last4 = null;
            
        }
    }
    public class Subscriptions {
        public String object_z {get;set;} // in json: object
        public List<Preferred_locales> data {get;set;} 
        public Boolean has_more {get;set;} 
        public Integer total_count {get;set;} 
        public String url {get;set;} 
        public Subscriptions(){
            object_z = null;
            data = new List<Preferred_locales>();
            has_more = null;
            total_count = null;
            url= null;          
        }
    }
    public class Owner {
        public String address {get;set;} 
        public String email {get;set;} 
        public String name {get;set;} 
        public String phone {get;set;} 
        public String verified_address {get;set;} 
        public String verified_email {get;set;} 
        public String verified_name {get;set;} 
        public String verified_phone {get;set;} 
        public Owner(){
            address =null;
            email = Null;
            name= Null;
            phone= Null;
            verified_address = null;
            verified_email = null;
            verified_name = null;
            verified_phone = null;
        }
    }
    public class cardDetail{
        public Integer exp_month {get;set;} 
        public Integer exp_year {get;set;} 
        public String last4digits {get;set;}   
        public String expiration {get;set;}//updated-02092020
        public String brand {get;set;}
        
        public cardDetail(){
            exp_month =Null;
            exp_year= null;
            last4digits = null;
            brand= null;
            expiration=null;//updated-02092020
        }
    }
    public class MakeAppointmentForPortalModalClass{
        public String teacherId{get;set;}
        public String packageId{get;set;}
        public String enrolmentId{get;set;}
        public String centerId{get;set;}
        public Integer duration{get;set;}
        public String studentId{get;set;}
        public String parentId{get;set;}
        public String bookingdate{get;set;}
        public String startTime{get;set;}
        public string bookingId{get;set;}
        public MakeAppointmentForPortalModalClass(){
            teacherId = null;
            studentId = null;
            startTime =null;
            bookingId = null;
            parentId = null;
            bookingdate = null;
            centerId = null;
            duration = null;
            packageId = null;
            enrolmentId = null;
        }
    } 
    //for Mobile Notification Api
    public  class Notification{
        public String notificationId{get;set;}
        public String title{get;set;}
        public String bodymsg{get;set;}
        public dateTime createdDate{get;set;}
        public Notification(String notificationId,String title,String bodymsg,dateTime createdDate){
            this.notificationId= notificationId;
            this.title = title;
            this.bodymsg = bodymsg;
            this.createdDate = createdDate;
        }
    }
    //for Mobile Notification Api List
    public class NotificationResult{
        public List<Notification> notifications{get;set;}
    }
   
    // Booking History list
    public class bookingHistoryResult{
        public List<String> bookingHistory;
        public bookingHistoryResult(){
            bookingHistory = New List<String>();
        }
    } 
    
    public class StripeCard{
        Public String stripeType;
        Public String country;
        Public String expiration;//updated-02092020
        Public Integer exp_month;
        Public String fingerprint;
        Public Integer exp_year;
        Public String last4;
        Public String stripeObject;
        Public String id;
        Public String name;
        public String brand;
        Public StripeError error;
        Public String customer_id;
        public Integer statusCode;
    }
public class StripeCustomer{
        Public Integer created;
        Public Integer account_balance;
        Public String description;
        Public StripeError error;
        Public Boolean livemode;
        public String default_source;
        Public String token;
        Public String id;
        Public Map<String, String> metadata;
        
        Public CardList cards;
        Public String default_card;
        public integer statusCode;
        public cls_sources sources;
    }
    public class cls_sources {
        public cls_data[] stripeData;
        public boolean has_more;
        public Integer total_count; //1
        public String url;  
    }   
    public class cls_data {
        public String id;   //card_1EQSP8Jja9IPifcSD7uJtvTz
        public String brand;    //Visa
        public String country;  //US
        public String customer; //cus_EuGxgjwNxGcLDd
        public String cvc_check;    //pass
        public Integer exp_month;   //4
        public Integer exp_year;    //2024
        public String fingerprint;  //DodUMgRQg0xbj77T
        public String funding;  //credit
        public String last4;    //4242
    }
    
    Public class CardList {
        Public Integer count;
        Public String url;
        Public List<StripeCard> stripeData;
    }
    Public class mobileAppError {
        public String errorCode{get;set;} 
        Public String message{get;set;} 
        public mobileAppError (){
            errorCode= null;  
            message= null; 
        }
    }
}