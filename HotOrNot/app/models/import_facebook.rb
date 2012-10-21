class ImportFacebook < ActiveRecord::Base
	attr_accessible :ImportFacebookID, :CouchEventID, :Count, :PollDate
	set_table_name "ImportFacebook"
	set_primary_key "ImportFacebookID"
	
	#belongs_to :poll_type, :foreign_key => "PollTypeID"
end
