class UserManager
	
	def new
	
	
	end
	
	def StartImport
		# Import all User records to establish event counts
		begin
			importUsers
			
			ErrorManager.LogError("Finished importing User records","User Import")		
		rescue Exception => e
			ErrorManager.LogException(e,"User Import")
		ensure
		end
	end
			
	def importUsers	
		require "net/http"
		require "uri"
		require "json"
		
		# Collect raw Event data from CouchDB		

		# Retrieve JSON records
		jsonMgr = JsonDocManager.new
		root = jsonMgr.getJsonDocumentWithAuthentication(Settings.CouchUserPath,Settings.CouchDBUserName,Settings.CouchDBPassword)
		
		if root != nil
			# Clear out table -
			ImportUser.delete_all
			
			pollDate = DateTime.now
		
			if root.has_key?("rows")
				objArr = root["rows"]
				objArr.each do |obj|
					if obj.has_key?("id")
						if obj["id"] != ""
							# User ID
							userID = obj["id"]
							
							if obj.has_key?("doc")
								docObj = obj["doc"]
								
								# Event list
								if docObj.has_key?("events")
									eventArr = docObj["events"]
									eventArr.each do |eventObj|
										if eventObj.has_key?("active")
											# Active Events only
											if eventObj["active"] == 1
												strEventID = eventObj["id"]
												# Parse timestamp
												dateAdded = nil
												begin
													# 08/13/12 17:17:53 +0000
													if eventObj["timestamp"].include? "+"
														dateAdded = Time.strptime(eventObj["timestamp"],"%m/%d/%y %H:%M:%S")
													else
														dateAdded = Time.parse(eventObj["timestamp"]).strftime("%Y-%m-%dT%H:%M:%Sz")
													end
												rescue Exception => e
													ErrorManager.LogException(e,eventObj["timestamp"])
												ensure
												end
											
												if !strEventID.blank? and strEventID != nil
													# Create ImportUser Record for each event
													userObj = ImportUser.new
													userObj.UserID = userID
													userObj.CouchEventID = strEventID
													userObj.DateAdded = dateAdded
													userObj.DatePolled = pollDate
													userObj.save
												end
											end										
										end
									end
								end
							end
						end
					end
				end
			end
		else
			# No JSON document - Log failure:
			ErrorManager.LogError("Failed to retrieve JSON for " + Settings.CouchUserPath,"User Import")
		end
	end
	
end
