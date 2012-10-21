class HomeController < ApplicationController

  def index
	
	# Retrieve 
	reloadReport = true
	if params[:sortColumnName] != nil
		@sortColumnName =  params[:sortColumnName]
		reloadReport = false # Sort command - don't recompile
	else
		@sortColumnName = "CouchEventID"
	end

	sortOrder = params[:sortOrder]
	if sortOrder == nil		
		sortOrder = "ASC"
	end
	@eventURL = Settings.BaseEventURL
	
	if params[:startDate] != nil && params[:endDate] != nil
		if reloadReport
			self.compileReport
		end
	end
	
	# Global variable consumed by form
	sessionID = request.session_options[:id]
	@result = CompileReport.select('*').where('"SessionID"=\'' + sessionID + '\'').order('"' + @sortColumnName + '" ' + sortOrder)
	@result = @result.paginate(:page => params[:page], :per_page => Settings.ReportPageSize)
  end
  
  def compileReport
	require 'will_paginate'
	require 'will_paginate/array' 
  
	@recordCount = CompileReport.count

	# Start Date
	begin
		# Test for parameter existence (sorting)
		@startDate = Date.parse(params[:startDate])
	rescue
		# Parse date selectors from form
		startDate = Date.civil(params[:startDate][:year].to_i, params[:startDate][:month].to_i, params[:startDate][:day].to_i)
		@startDate = startDate
	end
	
	# End Date
	begin
		# Test for parameter existence (sorting)
		@endDate = Date.parse(params[:endDate])
	rescue
		# Parse date selectors from form
		endDate = Date.civil(params[:endDate][:year].to_i, params[:endDate][:month].to_i, params[:endDate][:day].to_i)
		@endDate = endDate
	end
	
	#Retain text values
	@eventName = params[:txtEventName]
	@eventID = params[:txtEventID]

	# Compile data for date range
	self.runReport(@eventName,@eventID,startDate,endDate)
  end
  
  def performSort
	
	# Handles column sorting
	lastColName = "CouchEventID"
	if session[:lastColumnName] != nil
		lastColName = session[:lastColumnName].to_s
	end	
	
	sortOrder = "ASC"
	colName = params[:columnName]
	if lastColName != colName
		sortOrder = "ASC"
	else
		sortOrder = "DESC"
	end
	
	# Retain last sort column name
	session[:lastColumnName] = colName

	# Need to send post parameters (ugh!) to index() method
	redirect_to :action => :index, :startDate => params[:startDate], :endDate => params[:endDate], :txtEventName => params[:txtEventName], :txtEventID => params[:txtEventID], :sortColumnName => params[:columName], :sortOrder => sortOrder
  end
  
  def runReport(eventName,eventID,startDate,endDate)
	
	sessionID = request.session_options[:id]
	
	# Clear report table by session ID
	sql = 'delete from "CompileReport"
			WHERE "SessionID"=\'' + sessionID + '\';'
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(sql)

	# Insert Events
	sql = 'insert into "CompileReport"
	(
		"CouchEventID",
		"Capacity",
		"EventName",
		"SessionID"
	)
	select "CouchEventID","RoomCapacity","EventName",\'' + sessionID + '\'
	from "EventProfile"
	where "IsDeleted" = false'
	
	# Event Name
	if eventName != nil and !eventName.empty?
		sql += ' AND upper("EventName") like upper(\'%' + eventName + '%\')'
	end
	
	# Event ID
	if eventID != nil and !eventID.empty?
		sql += ' AND upper("CouchEventID") like upper(\'%' + eventID + '%\')'
	end
	sql += ';'
	
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(sql)	

	# FB for START date
	sql = 'update "CompileReport" as r
		set "FBCountStart" = q."Count"
	from
	(
		select "CouchEventID","Count"
		from "ImportFacebook"
		where date("PollDate") <= date(?)
	) as q
	where r."CouchEventID"=q."CouchEventID"
		AND r."SessionID"=\'' + sessionID + '\';'
	qry = ActiveRecord::Base.send(:sanitize_sql_array, [sql, startDate])
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(qry)
		
	# FB for END date 
	sql = 'update "CompileReport" as r
	set "FBCountEnd" = q."Count"
	from
	(
		select "CouchEventID","Count"
		from "ImportFacebook"
		where date("PollDate") <= date(?)
	) as q
	where r."CouchEventID"=q."CouchEventID"
		AND r."SessionID"=\'' + sessionID + '\';'
	qry = ActiveRecord::Base.send(:sanitize_sql_array, [sql, endDate])
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(qry)
	
	# Calculate FB Counts added within range
	sql = 'update "CompileReport"
	set "FBCountTotal"=coalesce("FBCountEnd",0)-coalesce("FBCountStart",0);'
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(sql)

	# Registration Adds for START Date: All/total adds up to this date
	sql = 'update "CompileReport" as r
	set "RegCountStart" = q."ct"
	from
	(
		select "CouchEventID",count(distinct "UserID") as ct
		from "ImportUser"
		where date("DateAdded") <= date(?)
		group by "CouchEventID"
	) as q
	where r."CouchEventID" = q."CouchEventID"
		AND r."SessionID"=\'' + sessionID + '\';'
	qry = ActiveRecord::Base.send(:sanitize_sql_array, [sql, startDate])
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(qry)
	
	# Registration Adds for END Date: All/total adds up to this date
	sql = 'update "CompileReport" as r
		set "RegCountEnd" = q."ct"
		from
		(
			select "CouchEventID",count(distinct "UserID") as ct
			from "ImportUser"
			where date("DateAdded") <= date(?)
			group by "CouchEventID"
		) as q
		where r."CouchEventID" = q."CouchEventID"
		AND r."SessionID"=\'' + sessionID + '\';'
 	qry = ActiveRecord::Base.send(:sanitize_sql_array, [sql, endDate])
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(qry)

	# Calculate Counts added within range 
	sql = 'update "CompileReport"
	set "RegCountTotal"=coalesce("RegCountEnd",0)-coalesce("RegCountStart",0);'
  	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(sql)
	
	# Calculate percentage of capacity 
	sql = 'update "CompileReport" 
	set "CapacityPercent" = round(("RegCountTotal"::decimal / "Capacity"::decimal) * 100)
	where coalesce("Capacity",0) > 0
		and coalesce("RegCountTotal",0) > 0 		
		AND "SessionID"=\'' + sessionID + '\';'
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(sql)

	# Twitter START count 
	sql = 'update "CompileReport" as r
	set "TwitterCountStart" = q."ct"
	from
	(
		select "CouchEventID",count(distinct "TwitterID") as ct
		from "CompileTwitter"
		where date("TwitterDate") <= date(?)
		group by "CouchEventID"
	) as q
	where r."CouchEventID"=q."CouchEventID"
		AND r."SessionID"=\'' + sessionID + '\';'
	qry = ActiveRecord::Base.send(:sanitize_sql_array, [sql, startDate])
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(qry)
	
	# Twitter END count 
	sql = 'update "CompileReport" as r
	set "TwitterCountEnd" = q."ct"
	from
	(
		select "CouchEventID",count(distinct "TwitterID") as ct
		from "CompileTwitter"
		where date("TwitterDate") <= date(?)
		group by "CouchEventID"
	) as q
	where r."CouchEventID"=q."CouchEventID"
		AND r."SessionID"=\'' + sessionID + '\';'
 	qry = ActiveRecord::Base.send(:sanitize_sql_array, [sql, endDate])
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(qry)

	# Calculate Counts added within range
	sql = 'update "CompileReport"
	set "TwitterCountTotal"=coalesce("TwitterCountEnd",0)-coalesce("TwitterCountStart",0)
	WHERE "SessionID"=\'' + sessionID + '\';'
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(sql)
  end
  
  def updateRanking
	sql = 'update "EventProfile" as p
	set "Ranking" = q."Rank"
	from
	(
		select "CouchEventID",
			( (("RegCountEnd" - coalesce("RegCountStart",0)) / "RegCountStart") +
			(("FBCountEnd" - coalesce("FBCountStart",0)) / coalesce("FBCountStart",1)) +
			(("TwitterCountEnd" - coalesce("TwitterCountStart",0)) / coalesce("TwitterCountStart",1)) ) / 3 as "Rank"
		from "CompileReport" 
		WHERE "SessionID"=\'' + sessionID + '\'
	) as q
	where p."CouchEventID"=q."CouchEventID";'
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(sql)  
	
	redirect_to :action => :index
  end

end
