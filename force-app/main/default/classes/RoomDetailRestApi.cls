@RestResource(urlMapping='/updateroomdetail/*')

global class RoomDetailRestApi {  
    @HttpGet
    global static String getRoomDetail() {
        RestRequest req = RestContext.request;
        String bookingId = req.params.get('booking_id');
        String roomId = req.params.get('room_id');
        system.debug('bookingId'+bookingId);
        system.debug('roomId'+roomId);
        if(bookingId != null && roomId != null){
        	Booking__c bObj= [SELECT Id, Room_Id__c FROM Booking__c where Id=:bookingId ];
        	bObj.Room_Id__c=roomId;
            
            if(bObj != null){
        		Update bObj;
            	return 'Success';
        	}else{
            	return 'Error';
        	}
        }
        return 'Error';
    }   
}