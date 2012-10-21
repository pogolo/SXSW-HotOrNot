class ImportEvent < ActiveRecord::Base
	attr_accessible :Import_EventID, :CouchEventID, :EventDate, :RoomCapacity, :HashTag, :EventName

  	set_table_name "ImportEvent"
	set_primary_key "Import_EventID"
end
