class ImportTwitter < ActiveRecord::Base
	attr_accessible :ImportTwitterID, :CouchEventID, :TwitterID, :PollDate, :TwitterDate

  	set_table_name "ImportTwitter"
	set_primary_key "ImportTwitterID"
end
