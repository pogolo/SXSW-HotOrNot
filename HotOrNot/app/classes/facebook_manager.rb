class FacebookManager

	def new
	
	end
	
	def PollAll
		begin	
			# Run on all active (not deleted) Event Profiles
			eventList = EventProfile.where('"IsDeleted"=false AND "CouchEventID" is not null')
			pollFacebook(eventList)
			
			# Log completion
			ErrorManager.LogError("Finished importing Facebook records","Facebook Import")
		rescue Exception => e
			ErrorManager.LogException(e,"Facebook Import")
		ensure
		end
	end
	
	def pollFacebook(eventList)
	
		if eventList.count == 0
			return
		end
		
		eventURL = Settings.BaseEventURL
		fbBaseURL = Settings.FacebookBaseURL
		pollDate = DateTime.now
		
		# Loop through all Events
		eventList.each do |eventInfo|
			shareURL = fbBaseURL + "/?id=" + eventURL + eventInfo.CouchEventID							
			root = getJSONDoc(shareURL)
			
			if root != nil
				if root.has_key?("shares")
					shareCount = 0
					begin
						shareCount = Integer(root["shares"])
					rescue
					ensure
					end
					
					# Add ImportFacebook record (no compilation required)
					pollInfo = ImportFacebook.new
					pollInfo.CouchEventID = eventInfo.CouchEventID
					pollInfo.Count = shareCount
					pollInfo.PollDate = pollDate
					pollInfo.save						
				end
			end
		end
	end
	
	def getJSONDoc(targetURL)
		# TODO: Handle this:
		#{
		#   "error": {
		#	  "message": "(#4) Application request limit reached",
		#	  "type": "OAuthException",
		#	  "code": 4
		#	}
		#}
		
		jsonMgr = JsonDocManager.new
		root = jsonMgr.getJsonDocument(targetURL)
		if hasRateLimitError(root)
			# Log rate limit error:
			ErrorManager.LogError(errorObj["message"],"Facebook Import")
			
			# Wait loop
			ct=0
			while hasRateLimitError(root) and ct < 3
				puts "Rate limit detected in Facebook API message. Sleeping..." + String(ct)
				sleep 60*5
				root = jsonMgr.getJsonDocument(targetURL)
				ct+=1
			end			
		end
		if hasError(root)
			root = nil
		end
		return root
	end
	
	def hasError(root)
		if root != nil
			if root.has_key?("error")
				return true
			end
		end
		return false
	end
	
	def hasRateLimitError(root)
		if root != nil
			if root.has_key?("error")
				errorObj = root["error"]
				# Rate limit?
				if errorObj.has_key?("code")
					if errorObj["code"] == 4
						return true
					else
						# Log other error
						ErrorManager.LogError(errorObj.join,"Facebook Import")	
					end
				end
			end
		end
		return false
	end
	
end