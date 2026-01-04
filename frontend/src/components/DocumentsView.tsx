import React from "react";
import {
  FileText,
  Download,
  Image,
  FileCode,
  FileSpreadsheet,
  X,
  FolderOpen,
} from "lucide-react";
import { useProject } from "../contexts/ProjectContext";
import { getFullFileUrl } from "../utils/url";

export const DocumentsView: React.FC = () => {
  const { files, isDocumentsSidebarOpen, toggleDocumentsSidebar } =
    useProject();

  if (!isDocumentsSidebarOpen) {
    return null;
  }

  const getFileIcon = (contentType: string) => {
    if (contentType.includes("image"))
      return <Image size={20} className="text-purple-400" />;
    if (contentType.includes("csv") || contentType.includes("spreadsheet"))
      return <FileSpreadsheet size={20} className="text-emerald-400" />;
    if (
      contentType.includes("json") ||
      contentType.includes("javascript") ||
      contentType.includes("python")
    )
      return <FileCode size={20} className="text-orange-400" />;
    return <FileText size={20} className="text-slate-400" />;
  };

  const formatSize = (bytes: number) => {
    if (bytes === 0) return "0 B";
    const k = 1024;
    const sizes = ["B", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  };

  return (
    <div className="w-80 bg-slate-900 border-l border-slate-800 flex flex-col h-full shadow-xl z-20">
      {/* Header */}
      <div className="p-6 border-b border-slate-800 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <FolderOpen size={20} className="text-orange-500" />
          <h2 className="font-semibold text-white">Project Files</h2>
        </div>
        <button
          onClick={toggleDocumentsSidebar}
          className="p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-all duration-200"
        >
          <X size={18} />
        </button>
      </div>

      {/* Files List */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3 custom-scrollbar">
        {files.length === 0 ? (
          <div className="flex flex-col items-center justify-center text-center py-12">
            <div className="p-4 bg-slate-800/50 rounded-2xl mb-4">
              <FolderOpen size={32} className="text-slate-600" />
            </div>
            <p className="text-sm font-medium text-slate-300 mb-1">
              No files yet
            </p>
            <p className="text-xs text-slate-500">
              Upload files in the chat to see them here
            </p>
          </div>
        ) : (
          files.map((file) => (
            <div
              key={file.id}
              className="group flex items-start gap-3 p-3 rounded-xl bg-slate-950/50 border border-slate-800 hover:border-orange-500/30 hover:shadow-md hover:shadow-orange-500/5 transition-all duration-200 animate-fade-in"
            >
              <div className="mt-0.5">{getFileIcon(file.content_type)}</div>
              <div className="flex-1 min-w-0">
                <p
                  className="text-sm font-medium truncate text-slate-300 group-hover:text-orange-400 transition-colors"
                  title={file.filename}
                >
                  {file.filename}
                </p>
                <p className="text-xs text-slate-500 mt-1">
                  {formatSize(file.byte_size)}
                </p>
              </div>
              <a
                href={getFullFileUrl(file.url)}
                download
                className="p-2 text-slate-500 hover:text-orange-500 hover:bg-orange-500/10 rounded-lg transition-all duration-200"
                title="Download"
              >
                <Download size={16} />
              </a>
            </div>
          ))
        )}
      </div>

      {/* Footer Stats */}
      {files.length > 0 && (
        <div className="p-4 border-t border-border bg-muted/20">
          <p className="text-xs text-muted-foreground text-center">
            {files.length} file{files.length !== 1 ? "s" : ""} in project
          </p>
        </div>
      )}
    </div>
  );
};
