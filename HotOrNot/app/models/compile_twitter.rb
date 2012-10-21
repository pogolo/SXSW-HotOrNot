class CompileTwitter < ActiveRecord::Base
	attr_accessible :CompileTwitterID, :CouchEventID, :TwitterID, :PollDate, :TwitterDate

  	set_table_name "CompileTwitter"
	set_primary_key "CompileTwitterID"
end
