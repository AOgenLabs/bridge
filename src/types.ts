// types.ts
// Type definitions for the AO Message Bridge

export interface Tag {
    name: string;
    value: string;
}

export interface Message {
    Tags: Tag[];
    Data: string;
    From?: string;
}

export interface ResultNode {
    Messages: Message[];
}

export interface ResultEdge {
    cursor: string;
    node: ResultNode;
}

export interface ResultsResponse {
    edges: ResultEdge[];
}

export interface EmailRequest {
    id: string;
    type: "email";
    to: string;
    subject: string;
    body: string;
    from: string;
    timestamp: number;
    status: string;
}

export interface DocumentRequest {
    id: string;
    type: "document";
    action: "create" | "list";
    fileName?: string;
    fileSize?: number;
    contentType?: string;
    content?: string;
    uploadedBy?: string;
    department?: string;
    timestamp: number;
    status: string;
}

export interface TelegramRequest {
    id: string;
    type: "telegram";
    chatId: string;
    message: string;
    parseMode?: "Markdown" | "HTML";
    disableNotification?: boolean;
    timestamp: number;
    status: string;
}

export type APIRequest = EmailRequest | DocumentRequest | TelegramRequest;

export interface APIResponse {
    success: boolean;
    status?: number;
    data?: any;
    error?: string;
}

export interface UpdateRequestData {
    requestId: string;
    result: APIResponse;
}
