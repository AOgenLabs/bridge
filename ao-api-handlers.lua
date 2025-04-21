-- ao-api-handlers.lua
-- A handler for API requests that uses message-based communication

-- Initialize state
if not ao.env then ao.env = {} end
if not ao.env.APIRequests then ao.env.APIRequests = {} end
if not ao.env.APIRequests.pending then ao.env.APIRequests.pending = {} end
if not ao.env.APIRequests.completed then ao.env.APIRequests.completed = {} end

-- Log a message with timestamp
local function log(message)
  print(os.date("%Y-%m-%d %H:%M:%S") .. " [APIHandler] " .. message)
end

-- Generate a unique ID
local function generateId()
  return "req-" .. os.time() .. "-" .. math.random(1000000)
end

-- Handler for sending emails
Handlers.add(
  "SendEmail",
  Handlers.utils.hasMatchingTag("Action", "SendEmail"),
  function(msg)
    log("Received SendEmail request from " .. msg.From)
    
    -- Parse the email data
    local emailData
    if type(msg.Data) == "string" then
      emailData = Utils.parseJson(msg.Data)
      if not emailData then
        log("Failed to parse email data as JSON")
        log("Raw data: " .. msg.Data)
        return
      end
    else
      emailData = msg.Data
    end
    
    -- Validate required fields
    if not emailData.to or emailData.to == "" then
      log("Error: Missing recipient")
      return
    end
    
    if not emailData.body or emailData.body == "" then
      log("Error: Missing email body")
      return
    end
    
    -- Set default values
    if not emailData.subject or emailData.subject == "" then
      emailData.subject = "No Subject"
    end
    
    if not emailData.from or emailData.from == "" then
      emailData.from = "noreply@example.com"
    end
    
    -- Create a request ID
    local requestId = generateId()
    
    -- Create the request object
    local request = {
      id = requestId,
      type = "email",
      to = emailData.to,
      subject = emailData.subject,
      body = emailData.body,
      from = emailData.from,
      timestamp = os.time(),
      status = "pending",
      requestedBy = msg.From
    }
    
    -- Store the request in pending requests
    ao.env.APIRequests.pending[requestId] = request
    
    log("Email request queued with ID: " .. requestId)
    
    -- Send a message to be picked up by the bridge
    -- Use "self" as the target to ensure it's recorded in the process history
    Send({
      Target = "self",
      Action = "APIRequest",
      Tags = {
        {name = "RequestType", value = "email"},
        {name = "RequestId", value = requestId},
        {name = "Status", value = "pending"}
      },
      Data = Utils.toJson(request)
    })
    
    -- Send response to the requester
    Send({
      Target = msg.From,
      Action = "EmailQueued",
      Data = Utils.toJson({
        success = true,
        requestId = requestId,
        message = "Email request queued for processing"
      })
    })
  end
)

-- Handler for creating documents
Handlers.add(
  "CreateDocument",
  Handlers.utils.hasMatchingTag("Action", "CreateDocument"),
  function(msg)
    log("Received CreateDocument request from " .. msg.From)
    
    -- Parse the document data
    local documentData
    if type(msg.Data) == "string" then
      documentData = Utils.parseJson(msg.Data)
      if not documentData then
        log("Failed to parse document data as JSON")
        log("Raw data: " .. msg.Data)
        return
      end
    else
      documentData = msg.Data
    end
    
    -- Validate required fields
    if not documentData.fileName or documentData.fileName == "" then
      log("Error: Missing fileName")
      return
    end
    
    -- Create a request ID
    local requestId = generateId()
    
    -- Create the request object
    local request = {
      id = requestId,
      type = "document",
      action = "create",
      fileName = documentData.fileName,
      fileSize = documentData.fileSize or 0,
      contentType = documentData.contentType or "application/octet-stream",
      content = documentData.content or "",
      uploadedBy = documentData.uploadedBy or "anonymous",
      department = documentData.department or "general",
      timestamp = os.time(),
      status = "pending",
      requestedBy = msg.From
    }
    
    -- Store the request in pending requests
    ao.env.APIRequests.pending[requestId] = request
    
    log("Document creation request queued with ID: " .. requestId)
    
    -- Send a message to be picked up by the bridge
    -- Use "self" as the target to ensure it's recorded in the process history
    Send({
      Target = "self",
      Action = "APIRequest",
      Tags = {
        {name = "RequestType", value = "document"},
        {name = "RequestAction", value = "create"},
        {name = "RequestId", value = requestId},
        {name = "Status", value = "pending"}
      },
      Data = Utils.toJson(request)
    })
    
    -- Send response to the requester
    Send({
      Target = msg.From,
      Action = "DocumentQueued",
      Data = Utils.toJson({
        success = true,
        requestId = requestId,
        message = "Document creation request queued for processing"
      })
    })
  end
)

-- Handler for listing documents
Handlers.add(
  "ListDocuments",
  Handlers.utils.hasMatchingTag("Action", "ListDocuments"),
  function(msg)
    log("Received ListDocuments request from " .. msg.From)
    
    -- Create a request ID
    local requestId = generateId()
    
    -- Create the request object
    local request = {
      id = requestId,
      type = "document",
      action = "list",
      timestamp = os.time(),
      status = "pending",
      requestedBy = msg.From
    }
    
    -- Store the request in pending requests
    ao.env.APIRequests.pending[requestId] = request
    
    log("List documents request queued with ID: " .. requestId)
    
    -- Send a message to be picked up by the bridge
    -- Use "self" as the target to ensure it's recorded in the process history
    Send({
      Target = "self",
      Action = "APIRequest",
      Tags = {
        {name = "RequestType", value = "document"},
        {name = "RequestAction", value = "list"},
        {name = "RequestId", value = requestId},
        {name = "Status", value = "pending"}
      },
      Data = Utils.toJson(request)
    })
    
    -- Send response to the requester
    Send({
      Target = msg.From,
      Action = "DocumentsQueued",
      Data = Utils.toJson({
        success = true,
        requestId = requestId,
        message = "List documents request queued for processing"
      })
    })
  end
)

-- Handler for updating request status (used by the bridge)
Handlers.add(
  "UpdateRequestStatus",
  Handlers.utils.hasMatchingTag("Action", "UpdateRequestStatus"),
  function(msg)
    log("Received UpdateRequestStatus request from " .. msg.From)
    
    -- Parse the update data
    local updateData
    if type(msg.Data) == "string" then
      updateData = Utils.parseJson(msg.Data)
      if not updateData then
        log("Failed to parse update data as JSON")
        log("Raw data: " .. msg.Data)
        return
      end
    else
      updateData = msg.Data
    end
    
    -- Validate required fields
    if not updateData.requestId or updateData.requestId == "" then
      log("Error: Missing requestId")
      return
    end
    
    if not updateData.result then
      log("Error: Missing result")
      return
    end
    
    -- Check if the request exists
    local request = ao.env.APIRequests.pending[updateData.requestId]
    
    if not request then
      log("Error: Request not found: " .. updateData.requestId)
      return
    end
    
    log("Updating status for request: " .. updateData.requestId)
    
    -- Update the request status
    request.status = updateData.result.success and "completed" or "failed"
    request.result = updateData.result
    request.completedAt = os.time()
    
    -- Move the request from pending to completed
    ao.env.APIRequests.completed[updateData.requestId] = request
    ao.env.APIRequests.pending[updateData.requestId] = nil
    
    -- Send a message to be picked up by the bridge
    -- Use "self" as the target to ensure it's recorded in the process history
    Send({
      Target = "self",
      Action = "APIRequest",
      Tags = {
        {name = "RequestType", value = request.type},
        {name = "RequestId", value = updateData.requestId},
        {name = "Status", value = "completed"}
      },
      Data = Utils.toJson(request)
    })
    
    -- Notify the requester
    if request.requestedBy then
      Send({
        Target = request.requestedBy,
        Action = request.type == "email" and "EmailProcessed" or "DocumentProcessed",
        Data = Utils.toJson(request)
      })
    end
    
    -- Send response to the bridge
    Send({
      Target = msg.From,
      Action = "RequestStatusUpdated",
      Data = Utils.toJson({
        success = true,
        requestId = updateData.requestId,
        message = "Request status updated"
      })
    })
  end
)

-- Initialize the handlers
log("API Handlers initialized")

-- Return the handler state
return {
  pending = ao.env.APIRequests.pending,
  completed = ao.env.APIRequests.completed
}
