import api from "./api";
import type { AuthResponse, User } from "../types";

export const login = async (
  email: string,
  password: string
): Promise<AuthResponse> => {
  const response = await api.post("/auth/login", { email, password });
  return response.data;
};

export const signup = async (
  name: string,
  email: string,
  password: string
): Promise<User> => {
  const response = await api.post("/users", {
    user: {
      name,
      email,
      password,
      password_confirmation: password,
    },
  });
  return response.data;
};

export const getCurrentUser = async (): Promise<User> => {
  const response = await api.get("/users/me");
  return response.data;
};
