import React from "react";
import { Layout } from "../components/Layout";
import { ConversationView } from "../components/ConversationView";
import { ProjectProvider } from "../contexts/ProjectContext";

export const DashboardPage: React.FC = () => {
  return (
    <ProjectProvider>
      <Layout>
        <ConversationView />
      </Layout>
    </ProjectProvider>
  );
};
