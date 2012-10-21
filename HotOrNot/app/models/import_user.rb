class ImportUser < ActiveRecord::Base
	attr_accessible :ImportUserID, :UserID, :CouchEventID, :DateAdded, :DatePolled

  	set_table_name "ImportUser"
	set_primary_key "ImportUserID"
end
