/**
    Name : DocumentWrapperForPianoRental
    Date: 16-Jan-2020
    Description: this controller Create PandaDoc form PandaDoc Dodument json wrapper
   
 
 */
public class DocumentWrapperForPianoRental{
    /*Create Document from PandaDoc Template json
    {  
    "name": "API Sample Document from PandaDoc Template",
    "template_uuid": "hryJY9mqYZHjQCYQuSjRQg",
    "folder_uuid": "QMDSzwabfFzTgjW4kUijqQ",
    "tags": [
       "tag_1",
       "tag_2"
    ],
    "recipients": [  
        {  
            "email": "jane@example.com",
            "first_name": "Jane",
            "last_name": "Roe",
            "role": "user"
        }
    ],
    "tokens": [  
        {  
            "name": "Favorite.Pet",
            "value": "Panda"
        }
    ],
    "fields": {  
        "Favorite.Color": {  
            "value": "PandaDoc green",
            "title": "Favorite.Color"
        },
        "Delivery": {
        	"value": "Same Day Delivery",
          "title": "Delivery"
        },
        "Like": {
        	"value": true
        },
        "Date": {
        	"value": "2019-12-31T00:00:00.000Z"
        }
    },
     "images": [
    	{
    		"name": "TextBlock1",
    		"urls": [
    			"https://s3.amazonaws.com/pd-static-content/public-docs/pandadoc-panda-bear.png"
    		]
    	}
    ],
    "metadata":{  
        "opp_id": "123456",
        "my_favorite_pet": "Panda"
    },
    "pricing_tables": [  
        {  
            "name": "PricingTable1",
            "options": {  
                "currency": "USD",
                "discount": {  
                    "is_global": true,
                    "type": "absolute",
                    "name": "Global Discount",
                    "value": 2.26
                }
            },
            "sections": [  
                {  
                    "title": "Sample Section",
                    "default": true,
                    "rows": [  
                        {  
                            "options": {  
                                "optional": true,
                                "optional_selected": true,
                                "qty_editable": true
                            },
                            "data":{  
                                "name": "Toy Panda",
                                "description": "Fluffy!",
                                "price": 10,
                                "qty": 3,
                                "tax_first": {  
                                    "value": 7.5,
                                    "type": "percent"
                                }
                            },
                            "custom_fields": {  
                                "Fluffiness": "5 / 5"
                            }
                        }
                    ]
                }
            ]
        }
    ]
}
    */
    Public Class CreateDocument{
        Public String name;
        Public String template_uuid;
        Public String folder_uuid;
        Public List<Recipients> recipients;
        Public List<Tokens> tokens;
       // Public List<PricingTable> pricing_tables;
        Public CustomField fields;
        Public MetaData metadata;
        Public CreateDocument(){
            tokens = new List<Tokens>();
           // pricing_tables = new List<PricingTable>();
            recipients = new List<Recipients>();
            metadata = new MetaData();
        }   
    }
    
    Public Class MetaData{
        Public String salesforceAccount_id;
    }
    
    

    Public Class CustomField{
        Public Fields Stairs;
        
        Public CustomField(Fields Stairs){
            this.Stairs = Stairs;
        }
    }
    
    Public Class Fields{
        Public String value;
        Public String title;
        Public Fields(String value, String title){
            this.value = value;
            this.title = title;
        }
        Public Fields(){}
    }
    
    Public Class Recipients{
        Public String email;
        Public String first_name;
        Public String last_name;
        Public String role;
        Public String recipient_type;
        Public Boolean has_completed;
        Public String id;
        
    }
    
    Public Class Tokens{
        Public String name;
        Public String value;
        Public Tokens(String name, String value){
            this.name = name;
            this.value = value;
        }
    }
    
  /*  Public Class PricingTable{
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
        Public CustomFields(String EnrolmentPackage, String DayTime, String CommencementDate){
            this.EnrolmentPackage = EnrolmentPackage;
            this.DayTime = DayTime;
            this.CommencementDate = CommencementDate;
        }
    }*/
    /*Move a document to sent status and send an optional email.
        {
            "message": "Hello! This document was sent from the PandaDoc API.",
            "subject": "Please check this test API document from PandaDoc",
            "silent": false
        }
     */
    Public Class SendDocument{
        Public String message;
        Public Boolean silent;
        Public SendDocument(String message, Boolean silent){
            this.message = message;
            this.silent = silent;
        }
    }
}