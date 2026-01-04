import api from "./api";
import type { Project, Message, Attachment } from "../types";

export const getProjects = async (): Promise<Project[]> => {
  const response = await api.get("/projects");
  return response.data;
};

export const createProject = async (
  name: string,
  description?: string
): Promise<Project> => {
  const response = await api.post("/projects", {
    project: { name, description },
  });
  return response.data;
};

export const getProjectMessages = async (
  projectId: number
): Promise<Message[]> => {
  const response = await api.get(`/projects/${projectId}/messages`);
  return response.data.messages;
};

export const deleteProjectMessages = async (
  projectId: number
): Promise<void> => {
  const response = await api.delete(`/projects/${projectId}/messages`);
  return response.data;
};

export const getProjectFiles = async (
  projectId: number
): Promise<Attachment[]> => {
  const response = await api.get(
    `/projects/${projectId}/messages/uploaded_files`
  );
  return response.data.uploaded_files || [];
};
