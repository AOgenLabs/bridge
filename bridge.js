// bridge.js
// A message bridge to integrate AO processes with backend APIs

import { readFileSync } from "node:fs";
import { message, results, createDataItemSigner } from "@permaweb/aoconnect";
import axios from "axios";
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

// Configuration
const AO_PROCESS_ID = process.env.AO_PROCESS_ID;
const EMAIL_API_URL = process.env.EMAIL_API_URL;
const DOCUMENT_API_URL = process.env.DOCUMENT_API_URL;
const CHECK_INTERVAL = parseInt(process.env.CHECK_INTERVAL || "10");
const ARWEAVE_WALLET_PATH = process.env.ARWEAVE_WALLET_PATH;

// Load Arweave wallet
let wallet;
try {
    wallet = JSON.parse(readFileSync(ARWEAVE_WALLET_PATH).toString());
    console.log("Arweave wallet loaded successfully");
} catch (error) {
    console.error("Error loading Arweave wallet:", error);
    process.exit(1);
}

// Create a signer using the wallet
const signer = createDataItemSigner(wallet);

// Track processed requests to avoid duplicates
const processedRequests = new Set();

// Track the last cursor for pagination
let lastCursor = null;

/**
 * Process email requests
 */
async function processEmailRequest(request) {
    try {
        console.log(`Processing email request: ${request.id}`);
        console.log(`Sending email to: ${request.to}`);
        console.log(`Subject: ${request.subject}`);

        // Make the API request
        const response = await axios({
            method: "post",
            url: EMAIL_API_URL,
            data: {
                to: request.to,
                subject: request.subject,
                body: request.body,
                from: request.from || "noreply@example.com",
            },
        });

        console.log(`Email API response: ${response.status}`);

        return {
            success: true,
            status: response.status,
            data: response.data,
        };
    } catch (error) {
        console.error(`Error processing email request ${request.id}:`, error);

        return {
            success: false,
            error: error.message,
        };
    }
}

/**
 * Process document requests
 */
async function processDocumentRequest(request) {
    try {
        console.log(`Processing document request: ${request.id}`);
        console.log(`Action: ${request.action}`);

        let response;

        // Handle different document actions
        switch (request.action) {
            case "create":
                console.log(`Creating document: ${request.fileName}`);
                response = await axios({
                    method: "post",
                    url: DOCUMENT_API_URL,
                    data: {
                        fileName: request.fileName,
                        fileSize: request.fileSize,
                        contentType: request.contentType,
                        content: request.content,
                        uploadedBy: request.uploadedBy,
                        department: request.department,
                    },
                });
                break;

            case "list":
                console.log("Listing documents");
                response = await axios({
                    method: "get",
                    url: DOCUMENT_API_URL,
                });
                break;

            default:
                throw new Error(`Unknown document action: ${request.action}`);
        }

        console.log(`Document API response: ${response.status}`);

        return {
            success: true,
            status: response.status,
            data: response.data,
        };
    } catch (error) {
        console.error(
            `Error processing document request ${request.id}:`,
            error
        );

        return {
            success: false,
            error: error.message,
        };
    }
}

/**
 * Process API requests
 */
async function processAPIRequest(request) {
    // Skip already processed requests
    if (processedRequests.has(request.id)) {
        console.log(`Skipping already processed request: ${request.id}`);
        return;
    }

    try {
        console.log(`Processing request: ${request.id}`);

        let result;

        // Process different request types
        switch (request.type) {
            case "email":
                result = await processEmailRequest(request);
                break;

            case "document":
                result = await processDocumentRequest(request);
                break;

            default:
                console.error(`Unknown request type: ${request.type}`);
                result = {
                    success: false,
                    error: `Unknown request type: ${request.type}`,
                };
        }

        // Mark the request as processed
        processedRequests.add(request.id);

        // Update the AO process with the result
        await updateRequestStatus(request.id, result);
    } catch (error) {
        console.error(`Error processing request ${request.id}:`, error);
    }
}

/**
 * Update the status of a request in the AO process
 */
async function updateRequestStatus(requestId, result) {
    try {
        console.log(`Updating request status: ${requestId}`);

        const updateResult = await message({
            process: AO_PROCESS_ID,
            tags: [{ name: "Action", value: "UpdateRequestStatus" }],
            data: JSON.stringify({
                requestId,
                result,
            }),
            signer,
        });

        console.log(`Request status updated: ${requestId}`);
        return updateResult;
    } catch (error) {
        console.error(`Error updating request status: ${error}`);
        return null;
    }
}

/**
 * Check for new API request messages
 */
async function checkForNewMessages() {
    try {
        console.log("Checking for new messages...");

        // Get the latest results
        const latestResults = await results({
            process: AO_PROCESS_ID,
            limit: 100,
            sort: "DESC",
            after: lastCursor,
        });

        if (
            !latestResults ||
            !latestResults.edges ||
            latestResults.edges.length === 0
        ) {
            console.log("No new messages found");
            return;
        }

        console.log(`Found ${latestResults.edges.length} messages`);

        // Update the last cursor for pagination
        if (latestResults.edges.length > 0) {
            lastCursor = latestResults.edges[0].cursor;
        }

        // Process each result
        for (const edge of latestResults.edges) {
            const result = edge.node;

            // Check if there are any messages
            if (!result.Messages || result.Messages.length === 0) {
                continue;
            }

            // Process each message
            for (const msg of result.Messages) {
                // Log all messages for debugging
                console.log("Message:", {
                    Tags: msg.Tags,
                    Data: msg.Data
                        ? msg.Data.substring(0, 100) + "..."
                        : "No data",
                });

                // Check if this is a message with an Action tag
                if (msg.Tags && msg.Tags.find((tag) => tag.name === "Action")) {
                    const actionTag = msg.Tags.find(
                        (tag) => tag.name === "Action"
                    );
                    const action = actionTag.value;

                    // Check if this is an API request action
                    if (
                        [
                            "SendEmail",
                            "CreateDocument",
                            "ListDocuments",
                        ].includes(action)
                    ) {
                        console.log(
                            `Found API request message with action: ${action}`
                        );

                        // Parse the request data
                        try {
                            const requestData = JSON.parse(msg.Data);
                            console.log("Request data:", requestData);

                            // Skip already processed requests
                            const referenceTag = msg.Tags.find(
                                (tag) => tag.name === "Reference"
                            );
                            if (
                                referenceTag &&
                                processedRequests.has(referenceTag.value)
                            ) {
                                console.log(
                                    `Skipping already processed request: ${referenceTag.value}`
                                );
                                continue;
                            }

                            // Create a request object based on the action
                            let request;

                            switch (action) {
                                case "SendEmail":
                                    request = {
                                        id: referenceTag
                                            ? referenceTag.value
                                            : `email-${Date.now()}`,
                                        type: "email",
                                        to: requestData.to,
                                        subject: requestData.subject,
                                        body: requestData.body,
                                        from:
                                            requestData.from ||
                                            "noreply@example.com",
                                        timestamp: Date.now(),
                                        status: "pending",
                                    };
                                    break;

                                case "CreateDocument":
                                    request = {
                                        id: referenceTag
                                            ? referenceTag.value
                                            : `doc-${Date.now()}`,
                                        type: "document",
                                        action: "create",
                                        fileName: requestData.fileName,
                                        fileSize: requestData.fileSize || 0,
                                        contentType:
                                            requestData.contentType ||
                                            "application/octet-stream",
                                        content: requestData.content || "",
                                        uploadedBy:
                                            requestData.uploadedBy ||
                                            "anonymous",
                                        department:
                                            requestData.department || "general",
                                        timestamp: Date.now(),
                                        status: "pending",
                                    };
                                    break;

                                case "ListDocuments":
                                    request = {
                                        id: referenceTag
                                            ? referenceTag.value
                                            : `list-${Date.now()}`,
                                        type: "document",
                                        action: "list",
                                        timestamp: Date.now(),
                                        status: "pending",
                                    };
                                    break;

                                default:
                                    console.log(
                                        `Skipping unknown action: ${action}`
                                    );
                                    continue;
                            }

                            // Process the request
                            await processAPIRequest(request);

                            // Mark the request as processed
                            if (referenceTag) {
                                processedRequests.add(referenceTag.value);
                            }
                        } catch (parseError) {
                            console.error(
                                "Error parsing request data:",
                                parseError
                            );
                            console.log("Raw data:", msg.Data);
                        }
                    }
                }
            }
        }
    } catch (error) {
        console.error("Error checking for new messages:", error);
    }
}

// Set up a loop to check for new messages
setInterval(checkForNewMessages, CHECK_INTERVAL * 1000);

console.log(
    `AO Message Bridge started. Checking every ${CHECK_INTERVAL} seconds...`
);

// Run once immediately
checkForNewMessages();
