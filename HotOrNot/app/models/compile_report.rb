class CompileReport < ActiveRecord::Base
	attr_accessible :CompileReportID,:CouchEventID,:EventName,:Capacity,:RegCountStart,:RegCountEnd,:RegCountTotal,:FBCountStart,:FBCountEnd,:FBCountTotal,:TwitterCountStart,:TwitterCountEnd,:TwitterCountTotal,:SessionID,:CapacityPercent,:EventName

  	set_table_name "CompileReport"
	set_primary_key "CompileReportID"
	
end
