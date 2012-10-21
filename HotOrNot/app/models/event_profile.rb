class EventProfile < ActiveRecord::Base
	attr_accessible :CouchEventID, :EventDate, :RoomCapacity, :IncrementTypeID, :IncrementValue, :LastUpdate, :IsDeleted, :HashTag, :EventName, :Ranking

  	set_table_name "EventProfile"
	set_primary_key "EventProfileID"
	
end
