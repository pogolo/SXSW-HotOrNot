class TwitterManager

	def new
	
	end
	
	def PollAll
		begin	
			# Run on all active (not deleted) Event Profiles with HashTag values
			eventList = EventProfile.where('"IsDeleted"=false and "HashTag" is not null')
			self.pollTwitter(eventList)
			
			# Compilation routines
			self.compileNewTweets
			#self.insertPollResults
			
			ErrorManager.LogError("Finished importing Twitter records","Twitter Import")
		rescue Exception => e
			ErrorManager.LogException(e,"Twitter Import")
		ensure
		end
	end
		
	def pollTwitter(eventList)
		require "net/http"
		require "uri"
		require "json"
		
		eventList ? nil : return
		eventList.count ? 0 : return
		
		# Clear all records from ImportTwitter table
		ImportTwitter.delete_all	
		
		twitterBaseURL = Settings.TwitterSearchURL
		twitterHashTag = Settings.TwitterHashTag
		jsonMgr = JsonDocManager.new # Retrieve JSON records
		
		eventList.each do |eventInfo|
			# Build hash tag list
			strHashTag = eventInfo.HashTag
			if strHashTag.include? ",#"
				arrHash = strHashTag.split(",#")
				strHashTag = arrHash.join(" ")
			end
			
			# Prepend "#SXSW" hash tag - Build Twitter request URI
			strHashTag = twitterHashTag + " " + strHashTag
			
		
			strURL = URI.escape(twitterBaseURL + "?q=" + strHashTag) # Escape URL
			
			# For testing - use URL for eco instead of hash tag
			# NOTE: Need to populate EventProfile.HashTag with "CouchEventID" values first
			# strURL = URI.escape(twitterBaseURL + "?q=" + Settings.BaseEventURL + eventInfo.CouchEventID)
			
			pollDate = DateTime.now
		
			# TODO: Handle rate limiting
			# HTTP Code 429 = rate limiting
			# https://dev.twitter.com/docs/error-codes-responses
		
		
			# Retrieve JSON doc
			root = jsonMgr.getJsonDocument(strURL)		
			if root != nil
				# Page through all results - exit out when running out of pages
				while true
					if root.has_key?("errors")
						# Error reported from Twitter
						# Log failure:
						ErrorManager.LogError(String(root["error"]),"Twitter Import")
						break
					else
						if root.has_key?("results")
							objArr = root["results"]
							if objArr.count == 0 or objArr.length == 0 # No results
								break # Exit paging loop
							end
							
							# Loop through results/individual Tweets on current page
							objArr.each do |resultObj|
								
								# Twitter User ID
								postID = nil
								if resultObj.has_key?("id_str")
									postID = resultObj["id_str"]
								end								

								# Tweet Date
								tweetDate = nil
								if resultObj.has_key?("created_at")
									begin
										tweetDate = DateTime.parse(resultObj["created_at"])
									rescue
									ensure
									end
								end								
									
								# Save ImportTwitter record to db:
								tRecord = ImportTwitter.new
								tRecord.CouchEventID = eventInfo.CouchEventID
								tRecord.TwitterID = postID
								tRecord.PollDate = pollDate
								tRecord.TwitterDate = tweetDate
								tRecord.save							
							end
							
							# Finished result loop - Check for subsequent pages
							if root.has_key?("next_page")
								if root["next_page"] != ""
									# Submit next request and process
									newURL = twitterBaseURL + root["next_page"]
									root = jsonMgr.getJsonDocument(newURL)
								else
									break # Exit paging loop
								end
							else
								break # Exit paging loop
							end
						else
							break # Exit paging loop
						end
					end
				end # end of JSON paging loop
			end
		end
	end
	
	def compileNewTweets
		# Maintain historic Tweet store. Insert only new Tweets.
		sql = 'insert into "CompileTwitter" ("CouchEventID","TwitterID","PollDate","TwitterDate")
			select distinct i."CouchEventID",i."TwitterID",i."PollDate",i."TwitterDate"
			from "ImportTwitter" as i left outer join
				"CompileTwitter" as c on i."TwitterID"=c."TwitterID" AND c."CouchEventID"=i."CouchEventID" AND c."TwitterDate"=i."TwitterDate"
			where c."CompileTwitterID" is null;'
		ActiveRecord::Base.establish_connection
	    ActiveRecord::Base.connection.execute(sql)	
	end

end