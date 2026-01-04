import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
} from "react";
import type { Project, Message, Attachment } from "../types";
import {
  getProjects,
  getProjectMessages,
  getProjectFiles,
  createProject as createProjectService,
  deleteProjectMessages,
} from "../services/project";
import { sendMessage as sendMessageService } from "../services/message";
import { useToast } from "./ToastContext";

interface ProjectContextType {
  projects: Project[];
  activeProject: Project | null;
  messages: Message[];
  files: Attachment[];
  isDocumentsSidebarOpen: boolean;
  isLoadingProjects: boolean;
  isLoadingMessages: boolean;
  setActiveProject: (project: Project | null) => void;
  toggleDocumentsSidebar: () => void;
  refreshProjects: () => Promise<void>;
  createNewProject: (name: string, description?: string) => Promise<void>;
  sendMessage: (content: string, files?: File[]) => Promise<void>;
  clearMessages: () => Promise<void>;
  containerId: string | undefined;
}

const ProjectContext = createContext<ProjectContextType | undefined>(undefined);

export const ProjectProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [projects, setProjects] = useState<Project[]>([]);
  const [activeProject, setActiveProject] = useState<Project | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [files, setFiles] = useState<Attachment[]>([]);
  const [isDocumentsSidebarOpen, setIsDocumentsSidebarOpen] = useState(true);
  const [isLoadingProjects, setIsLoadingProjects] = useState(false);
  const [isLoadingMessages, setIsLoadingMessages] = useState(false);
  const [containerId, setContainerId] = useState<string | undefined>(undefined);
  const { addToast } = useToast();

  const refreshProjects = useCallback(async () => {
    setIsLoadingProjects(true);
    try {
      const data = await getProjects();
      setProjects(data);
    } catch {
      addToast("Failed to load projects", "error");
    } finally {
      setIsLoadingProjects(false);
    }
  }, [addToast]);

  useEffect(() => {
    refreshProjects();
  }, [refreshProjects]);

  useEffect(() => {
    if (activeProject) {
      setIsLoadingMessages(true);
      Promise.all([
        getProjectMessages(activeProject.id),
        getProjectFiles(activeProject.id),
      ])
        .then(([msgs, projectFiles]) => {
          setMessages(msgs);
          setFiles(projectFiles);
          // Reset container ID when switching projects, or maybe we should persist it per project?
          // For now, let's assume a fresh session per project load unless we store it in DB.
          // If the backend persists session per project, we might not need to track it here explicitly
          // unless it's returned per message.
          setContainerId(undefined);
        })
        .catch(() => {
          addToast("Failed to load project data", "error");
        })
        .finally(() => setIsLoadingMessages(false));
    } else {
      setMessages([]);
      setFiles([]);
    }
  }, [activeProject, addToast]);

  const createNewProject = async (name: string, description?: string) => {
    try {
      const newProject = await createProjectService(name, description);
      setProjects((prev) => [newProject, ...prev]);
      setActiveProject(newProject);
      addToast("Project created successfully", "success");
    } catch {
      addToast("Failed to create project", "error");
    }
  };

  const sendMessage = async (content: string, uploadFiles?: File[]) => {
    if (!activeProject) return;

    // Optimistic update
    const tempId = Date.now();
    const tempMessage: Message = {
      id: tempId,
      role: "user",
      content,
      attachments: [], // Attachments will be loaded after response
      created_at: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, tempMessage]);

    try {
      const response = await sendMessageService({
        projectId: activeProject.id,
        content,
        files: uploadFiles,
        containerId,
        enableCodeExecution: true,
      });

      // Replace temp message with real one and add assistant response if included in the same call
      // But usually the response contains the assistant message or the user message confirmation.
      // Let's assume the response returns the user message created and we might need to fetch the assistant response
      // or the backend returns both? The interface says `message: Message`.
      // If it's a chat, usually we get the assistant response.
      // Let's assume the backend returns the assistant response or we need to poll/stream.
      // Based on "Assistant Content Rendering", it implies we get a response.

      // If the backend returns the *user* message, we need to wait for the assistant.
      // If the backend returns the *assistant* message, we append it.
      // Let's assume the backend returns the assistant's response or the updated conversation.
      // The `sendMessage` service returns `{ message: Message; container_id?: string }`.
      // If this `message` is the assistant's response, we append it.

      // Actually, usually we want to see our own message confirmed.
      // Let's assume we refresh messages or append the result.

      // For now, let's append the returned message (which is likely the assistant's response or the user's message with attachments processed).
      // If it's the user message, we replace the temp one.
      // If it's the assistant message, we keep the temp one (maybe update ID) and append assistant.

      // Let's assume the backend is synchronous for now (or we'd need websockets/polling).
      // Backend returns both user_message and assistant_message

      // Replace temp message with the real user message and add assistant message
      setMessages((prev) =>
        prev
          .map((m) => (m.id === tempId ? response.user_message : m))
          .concat(response.assistant_message)
      );

      if (response.container_id) {
        setContainerId(response.container_id);
      }

      // Refresh files as new ones might be generated
      getProjectFiles(activeProject.id).then(setFiles);
    } catch {
      setMessages((prev) => prev.filter((m) => m.id !== tempId));
      addToast("Failed to send message", "error");
    }
  };

  const clearMessages = async () => {
    if (!activeProject) return;
    try {
      await deleteProjectMessages(activeProject.id);
      setMessages([]);
      addToast("Conversation cleared", "success");
    } catch {
      addToast("Failed to clear conversation", "error");
    }
  };

  const toggleDocumentsSidebar = () => {
    setIsDocumentsSidebarOpen((prev) => !prev);
  };

  return (
    <ProjectContext.Provider
      value={{
        projects,
        activeProject,
        messages,
        files,
        isDocumentsSidebarOpen,
        isLoadingProjects,
        isLoadingMessages,
        setActiveProject,
        toggleDocumentsSidebar,
        refreshProjects,
        createNewProject,
        sendMessage,
        clearMessages,
        containerId,
      }}
    >
      {children}
    </ProjectContext.Provider>
  );
};

// eslint-disable-next-line react-refresh/only-export-components
export const useProject = () => {
  const context = useContext(ProjectContext);
  if (!context) {
    throw new Error("useProject must be used within a ProjectProvider");
  }
  return context;
};
