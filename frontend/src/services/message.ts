import api from "./api";
import type { Message } from "../types";

interface SendMessageParams {
  projectId: number;
  content: string;
  files?: File[];
  containerId?: string;
  enableCodeExecution?: boolean;
  model?: string;
}

export const sendMessage = async ({
  projectId,
  content,
  files,
  containerId,
  enableCodeExecution = true,
  model = "claude-sonnet-4-5",
}: SendMessageParams): Promise<{
  user_message: Message;
  assistant_message: Message;
  container_id?: string;
  model_used: string;
}> => {
  const formData = new FormData();
  formData.append("message[content]", content);
  formData.append("message[model]", model);

  if (containerId) {
    formData.append("container_id", containerId);
  }

  if (enableCodeExecution) {
    formData.append("enable_code_execution", "true");
  }

  if (files) {
    files.forEach((file) => {
      formData.append("files[]", file);
    });
  }

  const response = await api.post(`/projects/${projectId}/messages`, formData, {
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });

  return response.data;
};
