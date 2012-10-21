class EventManager
	
	def new
	
	
	end
	
	def StartImport
		# Import all events
		begin
			importEvents
			updateEventProfiles
			
			ErrorManager.LogError("Finished importing Event records","Event Import")		
		rescue Exception => e
			ErrorManager.LogException(e,"Event Import")
		ensure
		end
	end
		
	def importEvents	
		require "net/http"
		require "uri"
		require "json"
		
		# Collect raw Event data from CouchDB		

		# Retrieve JSON records
		jsonMgr = JsonDocManager.new
		root = jsonMgr.getJsonDocumentWithAuthentication(Settings.CouchDBAllEventsPath,Settings.CouchDBUserName,Settings.CouchDBPassword)
		
		if root != nil
			# Clear out table
			ImportEvent.delete_all
		
			if root.has_key?("rows")
				objArr = root["rows"]
				objArr.each do |obj|
					# Event ID
					if obj.has_key?("id")
						if obj.has_key?("doc")
							docObj = obj["doc"]
							
							# Event Name
							eventName = ""
							if docObj.has_key?("name")
								eventName = docObj["name"]
							end
							
							# Capacity
							eventCapacity = 0
							if docObj.has_key?("capacity")
								strCapacity = docObj["capacity"]	
								begin # Try/Catch to deal with garbage
									charArr=["-","/"]
									charArr.each do |val|
										if strCapacity.include? val
											# Range - get larger value
											tmpArr = strCapacity.split(val)
											strCapacity = tmpArr[1]
											break
										end
										eventCapacity = Integer(strCapacity)
									end
								rescue
									# Could log error here
								ensure
								end
							end
							
							# Twitter hash tag(s)
							strHashTag = nil
							if docObj.has_key?("hash_tags")
								hashTag=docObj["hash_tags"]
								if hashTag.kind_of?(Array)
									strHashTag = hashTag.join(",")
								else
									# Comma + space -or- space + # = multiple hash tags
									# Comma = single hash tag
									strHashTag = String(hashTag)
									arrSplitChar=[", "," #"]
									arrSplitChar.each do |splitChar|
										if strHashTag.include? splitChar
											arrTag = strHashTag.split(splitChar)
											newArr = Array.new
											ct=0
											arrTag.each do |tag|
												if !tag.include? "#"
													newArr[ct]="#" + tag # Prepend hash symbol
												else
													newArr[ct]=tag
												end
												ct=ct+1
											end
											strHashTag = newArr.join(",")
											break # Get out of arrSplitChar loop
										end
									end
								end
								
								if strHashTag != nil
									if strHashTag.empty?
										strHashTag = nil
									end
								end
							end

							# Event Date
							# Both yyyy/mm/dd and dd/mm/yyyy, some empty/null
							eventDate = nil
							if docObj.has_key?("date")
								begin
									eventDate = Date.parse(docObj["date"])
								rescue
									begin
										eventDate = Date.strptime(docObj["date"], "%m/%d/%Y")
									rescue
									ensure
									end
								ensure
								end
							end
									
							# Create Event Profile - save to db
							eventObj = ImportEvent.new
							eventObj.RoomCapacity = eventCapacity
							eventObj.CouchEventID = obj["id"]
							eventObj.EventDate = eventDate
							eventObj.HashTag = strHashTag
							eventObj.EventName = eventName
							eventObj.save							
						end
					end
				end
			end
		else
			# No JSON document - Log failure:
			ErrorManager.LogError("Failed to retrieve JSON for " + Settings.CouchDBAllEventsPath,"Event Import")
		end
	end
	
	def updateEventProfiles
		# Update
		sql = 'update "EventProfile" as e
		set "RoomCapacity"=i."RoomCapacity",
		"EventDate"=i."EventDate",
		"HashTag"=i."HashTag",
		"LastUpdate"=now(),
		"EventName"=i."EventName"
		from (
			select "CouchEventID","EventDate","RoomCapacity","HashTag","EventName"
			from "ImportEvent"
		) as i
		where i."CouchEventID"=e."CouchEventID"'			
		ActiveRecord::Base.establish_connection
	    ActiveRecord::Base.connection.execute(sql)	
		
		# Inserts
		sql = 'insert into "EventProfile" ("CouchEventID","EventDate","RoomCapacity","IncrementTypeID","IncrementValue","LastUpdate","IsDeleted","HashTag","EventName")
		select i."CouchEventID",i."EventDate",i."RoomCapacity",null,null,now(),false,i."HashTag",i."EventName"
		from "ImportEvent" as i left outer join
			"EventProfile" as p on i."CouchEventID"=i."CouchEventID"
		where p."CouchEventID" is null'
		ActiveRecord::Base.establish_connection
	    ActiveRecord::Base.connection.execute(sql)	
		
		# Mark Deletions
		sql = 'update "EventProfile"
		set "IsDeleted"=true
		where "CouchEventID" in
		(
			select p."CouchEventID"
			from "ImportEvent" as i right outer join
				"EventProfile" as p on p."CouchEventID"=i."CouchEventID"
			where i."CouchEventID" is null
		)'
		ActiveRecord::Base.establish_connection
	    ActiveRecord::Base.connection.execute(sql)
	end
	
end
