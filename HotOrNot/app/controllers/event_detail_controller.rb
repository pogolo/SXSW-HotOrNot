class EventDetailController < ApplicationController

def loadDetail
	@eventObj = nil
	@reportObj = nil
	
	eventInfo = EventProfile.where(:CouchEventID => params[:ID])
	reportInfo = CompileReport.where(:CouchEventID => params[:ID])
	if eventInfo != nil && reportInfo != nil
		@eventObj = eventInfo[0]
		@reportObj = reportInfo[0]
	end
end

end
