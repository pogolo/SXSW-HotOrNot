class ImportManager

	def new

	end

 def start
	
	puts "Importing Events"		
	EventManager.new.StartImport
	
	puts "Importing Users"
	UserManager.new.StartImport
	
	puts "Importing Facebook"
	FacebookManager.new.PollAll
	
	puts "Importing Twitter"
	TwitterManager.new.PollAll
	
	puts "Clearing out Reporting Compilation Table"
	CompileReport.delete_all
	
	puts "ErrorLog Maintenance"
	daysToKeep = Integer(Settings.ErrorLogAgeInDays)
	sql = 'DELETE from "ErrorLog" where "DateLogged" < (now()- INTERVAL \'? day\')'
	qry = ActiveRecord::Base.send(:sanitize_sql_array, [sql, daysToKeep])
	ActiveRecord::Base.establish_connection
	ActiveRecord::Base.connection.execute(qry)
	
 end
 
end