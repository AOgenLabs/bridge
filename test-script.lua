-- test-script.lua
-- A simple test script for AO that sends API requests

print("Starting Message Bridge Test...")

-- Function to send an email request
function sendEmailRequest()
  print("\n----- Sending Email Request -----")
  
  local emailData = {
    to = "test@example.com",
    subject = "Test Email from AO",
    body = "This is a test email sent from AO using the Message Bridge.",
    from = "ao@example.com"
  }
  
  print("Sending email to: " .. emailData.to)
  print("Subject: " .. emailData.subject)
  
  local result = Send({
    Target = "self",
    Action = "SendEmail",
    Data = Utils.toJson(emailData)
  })
  
  print("Email request sent")
  return result
end

-- Function to create a document
function createDocumentRequest()
  print("\n----- Creating Document Request -----")
  
  local documentData = {
    fileName = "Test Document.pdf",
    fileSize = 1024,
    contentType = "application/pdf",
    uploadedBy = "test@example.com",
    department = "Testing",
    content = "This is a test document created from AO using the Message Bridge."
  }
  
  print("Creating document: " .. documentData.fileName)
  
  local result = Send({
    Target = "self",
    Action = "CreateDocument",
    Data = Utils.toJson(documentData)
  })
  
  print("Document creation request sent")
  return result
end

-- Function to list documents
function listDocumentsRequest()
  print("\n----- Listing Documents Request -----")
  
  local result = Send({
    Target = "self",
    Action = "ListDocuments",
    Data = Utils.toJson({})
  })
  
  print("List documents request sent")
  return result
end

-- Run the test
print("\nRunning Message Bridge Test...")

-- Send an email request
local emailResult = sendEmailRequest()
print("Email request result: " .. Utils.toJson(emailResult))

-- Create a document
local documentResult = createDocumentRequest()
print("Document creation result: " .. Utils.toJson(documentResult))

-- List documents
local listResult = listDocumentsRequest()
print("List documents result: " .. Utils.toJson(listResult))

print("\nTest completed. Check the Message Bridge logs for request processing.")
print("The Message Bridge should detect these requests and process them.")

return "Message Bridge Test completed"
