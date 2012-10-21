class JsonDocManager

	def new
		
	end
	
	def getJsonDocument(strURL)
		return getJsonDocumentWithAuthentication(strURL,nil,nil)
	end
	
	def getJsonDocumentWithAuthentication(strURL,userName,password)
		require "net/http"
		require "uri"
		require "json"
		
		# Number of attempts to make before bagging
		attempts = Integer(Settings.HTTPNumberOfAttempts)
		
		# Build URI
		uri = URI.parse(strURL)
		http = Net::HTTP.new(uri.host, uri.port)
		if uri.scheme == "https"  # enable SSL/TLS
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		end
		request = Net::HTTP::Get.new(uri.request_uri)
		
		# Basic Authentication
		if userName != nil and password != nil
			request.basic_auth(userName, password)
		end
		
		response = nil		
		ct = 0
		while response == nil and ct < attempts
			# Attempt to connect:
			begin
				response = http.request(request)
			rescue  Exception => e
				# Error - usually "EOFError: End of file reached"
				ErrorManager.LogError(e.message,"JSONDocManager")
				response = nil
			ensure
			end
			ct += 1
		end
		
		if response != nil
			# if response != Net::HTTPSuccess
			intCode = Integer(response.code)
			if intCode < 200 and intCode > 299
			
				# Log error
				ErrorManager.LogError("HTTP Error: " + response.code,"JSONDocManager")
			
				# Handle API rate limiting
				# 429: Twitter rate limit
				# 613: Facebook rate limit FQL_EC_RATE_LIMIT_EXCEEDED
				# http://www.fb-developers.info/tech/fb_dev/faq/general/gen_10.html
				# http://fbdevwiki.com/wiki/Error_codes				
				tries = 0
				while (response.code == "429" || response.code == "613") and tries < 3
				
					# Wait 5 minutes
					puts "Rate limit detected in HTTP request code. Sleeping..."
					sleep 60*5
					
					# Try request again:
					ct = 0
					while response == nil and ct < attempts
						# Attempt to connect:
						begin
							response = http.request(request)
						rescue  Exception => e
							# Error - usually "EOFError: End of file reached"
							ErrorManager.LogError(e.message,"JSONDocManager")
							response = nil
						ensure
						end
						ct += 1
					end
					
					if response == nil
						# Failed to retrieve data
						return nil
					end
					
					tries += 1
				end
			end		

			# Try to return JSON doc
			begin
				return JSON.parse(response.body)
			rescue
				# Error during parsing
			ensure
			end
			
		end
		return nil
	end
	
end