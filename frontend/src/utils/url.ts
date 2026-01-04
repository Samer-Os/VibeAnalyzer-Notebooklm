export const getFullFileUrl = (path: string) => {
  if (!path) return "";
  if (path.startsWith("http")) return path;
  return `http://localhost:3000${path}`;
};
