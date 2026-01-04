import React, { useState, useRef, useEffect } from "react";
import {
  Send,
  Paperclip,
  File as FileIcon,
  X,
  Code,
  Terminal,
  Bot,
  User,
} from "lucide-react";
import ReactMarkdown from "react-markdown";
import { useProject } from "../contexts/ProjectContext";
import { cn } from "../utils/cn";
import { getFullFileUrl } from "../utils/url";

export const ConversationView: React.FC = () => {
  const { activeProject, messages, sendMessage, isLoadingMessages } =
    useProject();
  const [input, setInput] = useState("");
  const [files, setFiles] = useState<File[]>([]);
  const [isSending, setIsSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if ((!input.trim() && files.length === 0) || !activeProject || isSending)
      return;

    const content = input;
    const filesToSend = files;

    setInput("");
    setFiles([]);
    setIsSending(true);

    await sendMessage(content, filesToSend);
    setIsSending(false);
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setFiles((prev) => [...prev, ...Array.from(e.target.files!)]);
    }
  };

  const removeFile = (index: number) => {
    setFiles((prev) => prev.filter((_, i) => i !== index));
  };

  if (!activeProject) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center text-slate-500 p-8 bg-gray-50 dark:bg-slate-950">
        <div className="p-6 bg-white dark:bg-slate-900 rounded-3xl mb-6 shadow-xl shadow-orange-500/5 border border-slate-200 dark:border-slate-800">
          <Bot size={64} className="text-orange-500" />
        </div>
        <h2 className="text-2xl font-bold text-slate-800 dark:text-slate-100 mb-3">
          Select a project
        </h2>
        <p className="text-center max-w-md text-slate-500 dark:text-slate-400 leading-relaxed">
          Choose a project from the sidebar or create a new one to start
          analyzing with AI
        </p>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col h-full bg-gray-50 dark:bg-slate-950">
      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto p-6 custom-scrollbar">
        {isLoadingMessages ? (
          <div className="flex items-center justify-center h-full">
            <div className="flex flex-col items-center gap-4">
              <div className="w-12 h-12 border-4 border-orange-200 border-t-orange-500 rounded-full animate-spin" />
              <span className="text-slate-500 font-medium">
                Loading messages...
              </span>
            </div>
          </div>
        ) : messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-slate-500">
            <div className="p-6 bg-white dark:bg-slate-900 rounded-3xl mb-6 shadow-xl shadow-orange-500/5 border border-slate-200 dark:border-slate-800">
              <Bot size={48} className="text-orange-500" />
            </div>
            <h3 className="text-xl font-bold text-slate-800 dark:text-slate-100 mb-2">
              Start a conversation
            </h3>
            <p className="text-slate-500 dark:text-slate-400 text-center max-w-md leading-relaxed">
              Send a message or upload a file to begin analyzing with AI
            </p>
          </div>
        ) : (
          <div className="space-y-6 max-w-4xl mx-auto">
            {messages.map((message) => (
              <div
                key={message.id}
                className={cn(
                  "flex gap-4 animate-fade-in",
                  message.role === "user" ? "flex-row-reverse" : "flex-row"
                )}
              >
                {/* Avatar */}
                <div
                  className={cn(
                    "w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-lg shadow-orange-500/20",
                    message.role === "user"
                      ? "bg-gradient-to-br from-orange-500 to-orange-600"
                      : "bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700"
                  )}
                >
                  {message.role === "user" ? (
                    <User size={18} className="text-white" />
                  ) : (
                    <Bot size={18} className="text-orange-500" />
                  )}
                </div>

                {/* Message Content */}
                <div
                  className={cn(
                    "flex-1 rounded-2xl p-5 space-y-3 max-w-[85%] shadow-md",
                    message.role === "user"
                      ? "bg-gradient-to-br from-orange-500 to-orange-600 text-white rounded-tr-sm shadow-orange-500/20"
                      : "bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 rounded-tl-sm border border-slate-200 dark:border-slate-800"
                  )}
                >
                  <div
                    className={cn(
                      "prose prose-sm max-w-none leading-relaxed",
                      message.role === "user"
                        ? "prose-invert"
                        : "dark:prose-invert prose-headings:font-semibold prose-a:text-orange-500 prose-strong:text-slate-900 dark:prose-strong:text-white"
                    )}
                  >
                    <ReactMarkdown
                      components={{
                        code({
                          inline,
                          className,
                          children,
                          ...props
                        }: React.ComponentPropsWithoutRef<"code"> & {
                          inline?: boolean;
                        }) {
                          const match = /language-(\w+)/.exec(className || "");
                          return !inline && match ? (
                            <div className="relative rounded-xl overflow-hidden my-4 border border-border/50 bg-card shadow-md">
                              <div className="flex items-center justify-between px-4 py-2.5 bg-muted/50 border-b border-border/50 text-xs text-muted-foreground">
                                <span className="flex items-center gap-2 font-medium">
                                  {match[1] === "bash" ? (
                                    <Terminal
                                      size={14}
                                      className="text-primary"
                                    />
                                  ) : (
                                    <Code size={14} className="text-primary" />
                                  )}
                                  {match[1].toUpperCase()}
                                </span>
                              </div>
                              <div className="p-4 overflow-x-auto bg-card">
                                <code
                                  className={cn("text-sm font-mono", className)}
                                  {...props}
                                >
                                  {children}
                                </code>
                              </div>
                            </div>
                          ) : (
                            <code
                              className={cn(
                                "bg-muted/50 px-1.5 py-0.5 rounded-md text-sm font-mono border border-border/50",
                                className
                              )}
                              {...props}
                            >
                              {children}
                            </code>
                          );
                        },
                      }}
                    >
                      {message.content}
                    </ReactMarkdown>
                  </div>

                  {/* Attachments */}
                  {message.attachments && message.attachments.length > 0 && (
                    <div className="flex flex-wrap gap-2 mt-4 pt-3 border-t border-border/10">
                      {message.attachments.map((att) => (
                        <a
                          key={att.id}
                          href={getFullFileUrl(att.url)}
                          target="_blank"
                          rel="noopener noreferrer"
                          className={cn(
                            "flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-medium transition-all duration-200 border",
                            message.role === "user"
                              ? "bg-primary-foreground/10 hover:bg-primary-foreground/20 text-primary-foreground border-transparent"
                              : "bg-card hover:bg-card/80 text-foreground border-border/50 shadow-sm"
                          )}
                        >
                          <FileIcon size={14} />
                          <span className="truncate max-w-[140px]">
                            {att.filename}
                          </span>
                        </a>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            ))}

            {/* Sending indicator */}
            {isSending && (
              <div className="flex gap-4 animate-fade-in">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-accent to-accent/80 flex items-center justify-center shrink-0 shadow-soft">
                  <Bot size={18} className="text-accent-foreground" />
                </div>
                <div className="bg-secondary/50 rounded-2xl rounded-tl-sm p-5 shadow-sm">
                  <div className="flex items-center gap-2">
                    <div className="flex gap-1.5">
                      <div
                        className="w-2 h-2 bg-primary/60 rounded-full animate-bounce"
                        style={{ animationDelay: "0ms" }}
                      />
                      <div
                        className="w-2 h-2 bg-primary/60 rounded-full animate-bounce"
                        style={{ animationDelay: "150ms" }}
                      />
                      <div
                        className="w-2 h-2 bg-primary/60 rounded-full animate-bounce"
                        style={{ animationDelay: "300ms" }}
                      />
                    </div>
                    <span className="text-sm text-muted-foreground font-medium ml-2">
                      Thinking...
                    </span>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Area */}
      <div className="p-6 bg-gradient-to-t from-gray-50 via-gray-50 to-transparent dark:from-slate-950 dark:via-slate-950">
        <div className="max-w-4xl mx-auto">
          {/* Selected Files */}
          {files.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-4 px-1">
              {files.map((file, i) => (
                <div
                  key={i}
                  className="flex items-center gap-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-200 px-3 py-1.5 rounded-xl text-sm shadow-sm animate-fade-in"
                >
                  <div className="p-1 bg-orange-50 dark:bg-orange-500/10 rounded-md">
                    <FileIcon size={12} className="text-orange-500" />
                  </div>
                  <span className="truncate max-w-[120px] font-medium">
                    {file.name}
                  </span>
                  <button
                    onClick={() => removeFile(i)}
                    className="hover:text-red-500 transition-colors ml-1"
                  >
                    <X size={14} />
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* Input Form */}
          <form
            onSubmit={handleSend}
            className="relative flex items-end gap-2 bg-white dark:bg-slate-900 p-2 rounded-3xl border border-slate-200 dark:border-slate-800 shadow-xl shadow-orange-500/5 hover:shadow-2xl hover:shadow-orange-500/10 transition-all duration-300 ring-1 ring-black/5 dark:ring-white/5"
          >
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              className="p-3 text-slate-400 hover:text-orange-500 hover:bg-orange-50 dark:hover:bg-orange-500/10 rounded-full transition-all duration-200"
              title="Attach files"
            >
              <Paperclip size={20} />
            </button>
            <input
              type="file"
              ref={fileInputRef}
              onChange={handleFileSelect}
              className="hidden"
              multiple
              accept=".xlsx,.xls,.csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,text/csv"
            />

            <textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  handleSend(e);
                }
              }}
              placeholder="Message VibeAnalyzer..."
              className="flex-1 bg-transparent border-none focus:ring-0 resize-none max-h-32 py-3 text-sm placeholder:text-slate-400 text-slate-800 dark:text-slate-200 outline-none"
              rows={1}
              style={{ minHeight: "48px" }}
            />

            <button
              type="submit"
              disabled={(!input.trim() && files.length === 0) || isSending}
              className="p-3 bg-gradient-to-br from-orange-500 to-orange-600 text-white rounded-full hover:opacity-90 hover:shadow-lg hover:shadow-orange-500/30 hover:scale-105 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed disabled:shadow-none disabled:scale-100"
            >
              <Send size={18} className={cn(isSending && "animate-pulse")} />
            </button>
          </form>

          <div className="text-center mt-4">
            <p className="text-[10px] uppercase tracking-wider text-slate-400 font-medium">
              AI-Generated Content • Review Code Before Use
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
