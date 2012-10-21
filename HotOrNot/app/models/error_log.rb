class ErrorLog < ActiveRecord::Base
	attr_accessible :ErrorID, :Message, :StackTrace, :Module, :DateLogged

  	set_table_name "ErrorLog"
	set_primary_key "ErrorLogID"
end
