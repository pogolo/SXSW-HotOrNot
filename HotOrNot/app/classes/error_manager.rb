class ErrorManager

	# Static method
	def self.LogError(errorMessage,moduleDescription)	
		errorInfo = ErrorLog.new
		errorInfo.Message = String(errorMessage)
		errorInfo.Module = String(moduleDescription)
		errorInfo.DateLogged = DateTime.now
		errorInfo.save
	end
	
	def self.LogException(e,moduleDescription)
		errorInfo = ErrorLog.new
		if e != nil
			errorInfo.Message = e.message.to_s
			errorInfo.StackTrace = e.backtrace.join("\n")
		end
		errorInfo.Module = String(moduleDescription)
		errorInfo.DateLogged = DateTime.now
		errorInfo.save	
	end

end