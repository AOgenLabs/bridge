# AO Message Bridge

This project integrates AO processes with backend APIs using a message-based approach that focuses on detecting messages rather than accessing state directly.

## Components

1. **AO Handlers**: Lua scripts that run in the AO environment and send messages when API requests are received.
2. **Message Bridge**: A Node.js script that uses aoconnect's results function to check for new messages.
3. **Backend APIs**: Express.js servers that handle email and document requests.

## Setup

### 1. Install Dependencies

```bash
# Install dependencies for the Message Bridge
cd ao-message-bridge
npm install
```

### 2. Configure the Message Bridge

Edit the `.env` file in the `ao-message-bridge` directory to set the AO process ID and API endpoints:

```
# AO Process ID
AO_PROCESS_ID="your-ao-process-id"

# API Endpoints
EMAIL_API_URL="http://localhost:3001/api/email/send"
DOCUMENT_API_URL="http://localhost:3002/api/documents"

# Check interval in seconds
CHECK_INTERVAL=10

# Arweave wallet path
ARWEAVE_WALLET_PATH="path/to/your/arweave-wallet.json"
```

### 3. Start the Backend APIs

```bash
cd backend
npm start
```

This will start the email API server on port 3001 and the document API server on port 3002.

### 4. Start the Message Bridge

```bash
cd ao-message-bridge
npm start
```

This will start the Message Bridge, which will check for new messages every 10 seconds (or whatever interval you set in the `.env` file).

### 5. Load the AO Handlers

In the AO console, load the AO handlers:

```lua
.load ao-message-bridge/ao-api-handlers.lua
```

### 6. Test the Integration

In the AO console, load and run the test script:

```lua
.load ao-message-bridge/test-script.lua
```

This will send an email request, create a document request, and list documents, which will be processed by the Message Bridge.

## Usage

### Sending an Email

To send an email from an AO process, send a message with the following format:

```lua
Send({
  Target = "your-ao-process-id",
  Action = "SendEmail",
  Data = Utils.toJson({
    to = "recipient@example.com",
    subject = "Email Subject",
    body = "Email Body",
    from = "sender@example.com"
  })
})
```

### Creating a Document

To create a document from an AO process, send a message with the following format:

```lua
Send({
  Target = "your-ao-process-id",
  Action = "CreateDocument",
  Data = Utils.toJson({
    fileName = "document.pdf",
    fileSize = 1024,
    contentType = "application/pdf",
    content = "Document content",
    uploadedBy = "user@example.com",
    department = "Department"
  })
})
```

### Listing Documents

To list documents from an AO process, send a message with the following format:

```lua
Send({
  Target = "your-ao-process-id",
  Action = "ListDocuments",
  Data = Utils.toJson({})
})
```

## Architecture

1. **AO Process**: Sends API requests to itself using the AO handlers.
2. **AO Handlers**: Process the requests, store them in the process state, and send messages to be picked up by the Message Bridge.
3. **Message Bridge**: Checks for new messages and processes API requests.
4. **Backend APIs**: Handle email and document requests.

The Message Bridge uses aoconnect's results function to check for new messages, which is a more reliable approach than trying to access the state directly.

## How It Works

1. The AO process receives an API request (e.g., SendEmail).
2. The AO handler processes the request, stores it in the process state, and sends a message with the Action "APIRequest" and Status "pending".
3. The Message Bridge checks for new messages and processes any "APIRequest" messages with Status "pending" that it finds.
4. When a request is processed, the Message Bridge sends a message back to the AO process to update the request status.
5. The AO process updates the status of the request and sends a message with the Action "APIRequest" and Status "completed".
6. The AO process also notifies the requester.

## Troubleshooting

If you encounter any issues, check the logs of the Message Bridge and the backend APIs for error messages.

Common issues:

1. **AO Process ID**: Make sure the AO process ID in the `.env` file is correct.
2. **Arweave Wallet**: Make sure the Arweave wallet path in the `.env` file is correct.
3. **API Endpoints**: Make sure the API endpoints in the `.env` file are correct.
4. **AO Handlers**: Make sure the AO handlers are loaded in the AO process.

## License

This project is licensed under the MIT License.
