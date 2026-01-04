import React, { useState } from "react";
import {
  Plus,
  Search,
  LogOut,
  User as UserIcon,
  MessageSquare,
  Sparkles,
  Moon,
  Sun,
} from "lucide-react";
import { useProject } from "../contexts/ProjectContext";
import { useAuth } from "../contexts/AuthContext";
import { useTheme } from "../contexts/ThemeContext";
import { cn } from "../utils/cn";

export const Sidebar: React.FC = () => {
  const { projects, activeProject, setActiveProject, createNewProject } =
    useProject();
  const { user, logout } = useAuth();
  const { theme, setTheme } = useTheme();
  const [searchQuery, setSearchQuery] = useState("");
  const [isCreating, setIsCreating] = useState(false);
  const [newProjectName, setNewProjectName] = useState("");

  const filteredProjects = projects.filter((p) =>
    p.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleCreateProject = async (e: React.FormEvent) => {
    e.preventDefault();
    if (newProjectName.trim()) {
      await createNewProject(newProjectName);
      setNewProjectName("");
      setIsCreating(false);
    }
  };

  return (
    <div className="w-72 bg-slate-900 text-slate-100 border-r border-slate-800 flex flex-col h-full shadow-xl z-20">
      {/* Header */}
      <div className="p-6 border-b border-slate-800">
        <div className="flex items-center gap-3 mb-6">
          <div className="p-2.5 bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl shadow-lg shadow-orange-500/20">
            <Sparkles className="w-6 h-6 text-white" />
          </div>
          <h1 className="font-bold text-2xl tracking-tight text-white">
            VibeAnalyzer
          </h1>
        </div>
        <button
          onClick={() => setIsCreating(true)}
          className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-orange-500 to-orange-600 text-white py-3 px-4 rounded-xl font-semibold shadow-lg shadow-orange-500/25 hover:shadow-orange-500/40 hover:scale-[1.02] transition-all duration-200"
        >
          <Plus size={20} />
          New Project
        </button>
      </div>

      {/* Create Project Form */}
      {isCreating && (
        <form
          onSubmit={handleCreateProject}
          className="p-4 border-b border-slate-800 bg-slate-800/50 animate-fade-in"
        >
          <input
            type="text"
            placeholder="Project Name"
            value={newProjectName}
            onChange={(e) => setNewProjectName(e.target.value)}
            className="w-full px-4 py-3 rounded-xl border border-slate-700 bg-slate-950 text-white text-sm focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none transition-all placeholder:text-slate-500"
            autoFocus
          />
          <div className="flex gap-2 mt-3">
            <button
              type="submit"
              className="flex-1 bg-orange-500 text-white text-sm py-2 rounded-lg font-medium hover:bg-orange-600 transition-colors"
            >
              Create
            </button>
            <button
              type="button"
              onClick={() => setIsCreating(false)}
              className="flex-1 bg-slate-800 text-slate-300 text-sm py-2 rounded-lg font-medium hover:bg-slate-700 transition-colors"
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      {/* Search */}
      <div className="p-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-500" />
          <input
            type="text"
            placeholder="Search projects..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-800 bg-slate-950/50 text-slate-200 text-sm focus:bg-slate-950 focus:border-orange-500/50 focus:ring-2 focus:ring-orange-500/10 outline-none transition-all placeholder:text-slate-600"
          />
        </div>
      </div>

      {/* Projects List */}
      <div className="flex-1 overflow-y-auto px-3 py-2 space-y-1 custom-scrollbar">
        {filteredProjects.length === 0 ? (
          <div className="text-center py-8 text-slate-600 text-sm">
            No projects found
          </div>
        ) : (
          filteredProjects.map((project) => (
            <button
              key={project.id}
              onClick={() => setActiveProject(project)}
              className={cn(
                "w-full flex items-center gap-3 p-3 rounded-xl text-sm transition-all duration-200 group",
                activeProject?.id === project.id
                  ? "bg-orange-500/10 text-orange-400 border border-orange-500/20 shadow-sm"
                  : "text-slate-400 hover:bg-slate-800/50 hover:text-slate-200"
              )}
            >
              <MessageSquare
                size={18}
                className={cn(
                  "transition-colors",
                  activeProject?.id === project.id
                    ? "text-orange-500"
                    : "text-slate-600 group-hover:text-slate-400"
                )}
              />
              <span className="truncate font-medium">{project.name}</span>
            </button>
          ))
        )}
      </div>

      {/* User Section */}
      <div className="p-4 border-t border-slate-800 bg-slate-900/50">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-orange-500 to-orange-600 flex items-center justify-center shadow-lg shadow-orange-500/20">
            <UserIcon size={18} className="text-white" />
          </div>
          <div className="flex-1 overflow-hidden">
            <p className="text-sm font-medium truncate text-slate-200">
              {user?.name || user?.email}
            </p>
            <p className="text-xs text-slate-500 truncate">{user?.email}</p>
          </div>
        </div>

        <div className="flex items-center justify-between">
          <button
            onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
            className="flex items-center gap-2 text-sm text-slate-400 hover:text-white transition-colors px-3 py-2 rounded-lg hover:bg-slate-800"
          >
            {theme === "dark" ? <Sun size={16} /> : <Moon size={16} />}
            {theme === "dark" ? "Light" : "Dark"}
          </button>
          <button
            onClick={logout}
            className="flex items-center gap-2 text-sm text-slate-400 hover:text-red-400 transition-colors px-3 py-2 rounded-lg hover:bg-red-500/10"
          >
            <LogOut size={16} />
            Logout
          </button>
        </div>
      </div>
    </div>
  );
};
