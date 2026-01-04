import React from "react";
import { Sidebar } from "./Sidebar";
import { DocumentsView } from "./DocumentsView";
import { useProject } from "../contexts/ProjectContext";
import { PanelRightOpen } from "lucide-react";

interface LayoutProps {
  children: React.ReactNode;
}

export const Layout: React.FC<LayoutProps> = ({ children }) => {
  const { isDocumentsSidebarOpen, toggleDocumentsSidebar } = useProject();

  return (
    <div className="flex h-screen w-full overflow-hidden bg-gray-50 dark:bg-slate-950 text-foreground">
      <Sidebar />

      <main className="flex-1 flex flex-col min-w-0 relative bg-gray-50 dark:bg-slate-950">
        <div className="flex-1 flex overflow-hidden">{children}</div>

        {!isDocumentsSidebarOpen && (
          <button
            onClick={toggleDocumentsSidebar}
            className="absolute top-4 right-4 p-2.5 bg-white/80 dark:bg-slate-900/80 backdrop-blur-sm border border-slate-200 dark:border-slate-800 rounded-xl shadow-md hover:bg-white dark:hover:bg-slate-900 hover:border-orange-500/30 hover:shadow-lg transition-all duration-200 z-10"
            title="Open Documents"
          >
            <PanelRightOpen
              size={18}
              className="text-slate-500 dark:text-slate-400"
            />
          </button>
        )}
      </main>

      <DocumentsView />
    </div>
  );
};
