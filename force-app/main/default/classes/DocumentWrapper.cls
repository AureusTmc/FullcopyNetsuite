public class DocumentWrapper{
    
    Public Class CreateDocument{
        Public String name;
        Public String template_uuid;
        Public String folder_uuid;
        Public List<Recipients> recipients;
        Public List<Tokens> tokens;
        Public List<PricingTable> pricing_tables;
        Public CustomField fields;
        Public MetaData metadata;
        Public CreateDocument(){
            tokens = new List<Tokens>();
            pricing_tables = new List<PricingTable>();
            recipients = new List<Recipients>();
            metadata = new MetaData();
        }   
    }
    
    Public Class MetaData{
        Public String salesforceAccount_id;
    }
    
    Public Class CustomField{
        Public Fields ParentName;
        public Parent_Guardian_Name parentGuardianName {get;set;} 
        public Parent_Guardian_Name Selectdate {get;set;} 
        Public CustomField(Fields ParentName){
            this.ParentName = ParentName;
            parentGuardianName = new Parent_Guardian_Name();
            Selectdate = new Parent_Guardian_Name();
        }
        Public CustomField(Parent_Guardian_Name parentGuardianName, Parent_Guardian_Name Selectdate){
            this.parentGuardianName = parentGuardianName;
            this.Selectdate = Selectdate;
        }
    }
    
    Public Class Fields{
        Public String value;
        Public String title;
        Public Fields(String value, String title){
            this.value = value;
            this.title = title;
        }
    }
    
    Public Class Recipients{
        Public String email;
        Public String first_name;
        Public String last_name;
        Public String role;
    }
    
    Public Class Tokens{
        Public String name;
        Public String value;
    }
    
    Public Class PricingTable{
        Public String name;
        Public TableOptions options;
        Public List<Sections> sections;
        Public PricingTable(String name, List<Sections> sections){
            this.name = name;
            this.sections = new List<Sections>();
            options = new TableOptions();
            this.sections = sections;
        }        
    }
    
    Public Class Sections{
        Public String title;
        Public Boolean pandadoc_Default_Section_XYZ;
        Public List<Rows> rows;
        Public Sections(String title, List<Rows> rows){
            this.title = title;
            this.rows = new List<Rows>();
            this.pandadoc_Default_Section_XYZ = true;
            this.rows = rows;
        }
    }
    
    Public Class TableOptions{
        Public String pandadoc_Currency_Code_XYZ;
        Public Discount discount;
        Public TableOptions(){
            pandadoc_Currency_Code_XYZ = 'USD';
        	discount = new Discount();
        }
    }
    
    Public Class Discount{
        Public Boolean is_global;
        Public String type;
        Public String name;
        Public Decimal value;
        Public Discount(){
            is_global = false;
            type = 'absolute';
            name = 'Global Discount';
            value = 2.26;
        }
    }
    
    
    Public Class Rows{
        Public Options options;
        Public Data data;
        Public CustomFields custom_fields;
        Public Rows(Data data, CustomFields custom_fields){
            options = new Options();
            this.data = data;
            this.custom_fields = custom_fields;
        }
    }
    
    public Class Options{
    	Public Boolean optional;
        Public Boolean optional_selected;
        Public Boolean qty_editable;
        Public Options(){
            optional = false;
            optional_selected = false;
            qty_editable = false;
        }
    }
	
    Public Class Data{
        Public String name;
        Public Decimal price;
        Public Integer qty;
        Public Data(String name){
            this.name = name;
            price = 10;
            qty = 1;
        }
    }	
    
    Public Class CustomFields{
        Public String EnrolmentPackage;
        Public String DayTime;
        Public String CommencementDate;
        public String Text {get;set;} 
        public String Text1 {get;set;} 
        public String Text2 {get;set;}
        Public CustomFields(String EnrolmentPackage, String DayTime, String CommencementDate){
            this.EnrolmentPackage = EnrolmentPackage;
            this.DayTime = DayTime;
            this.CommencementDate = CommencementDate;
        }
        Public CustomFields(String EnrolmentPackage, String DayTime, String CommencementDate,String Text, String Text1, String Text2){
            this.EnrolmentPackage = EnrolmentPackage;
            this.DayTime = DayTime;
            this.CommencementDate = CommencementDate;
            this.Text = Text;
            this.Text1 = Text1;
            this.Text2 = Text2;
        }
    }
    
    Public Class SendDocument{
        Public String message;
        Public Boolean silent;
        Public SendDocument(String message, Boolean silent){
            this.message = message;
            this.silent = silent;
        }
    }
    public class Parent_Guardian_Name {
        public String value {get;set;} 
        public String title {get;set;}
        public Parent_Guardian_Name(String value, String title){
            this.value = value;
            this.title = title;
        }
        public Parent_Guardian_Name(){
            this.value = '';
            this.title = '';
        }
    }
}