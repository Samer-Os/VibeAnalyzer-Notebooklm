export interface User {
  id: number;
  name: string;
  email: string;
  role: string;
  created_at: string;
  updated_at: string;
}

export interface Attachment {
  id: number;
  file_id: string;
  filename: string;
  content_type: string;
  url: string;
  byte_size: number;
}

export interface Message {
  id: number;
  role: "user" | "assistant";
  content: string;
  attachments: Attachment[];
  created_at: string;
}

export interface Project {
  id: number;
  name: string;
  description: string;
  created_at: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}
