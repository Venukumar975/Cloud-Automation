import axios from "axios";

const api = axios.create({
  baseURL: "https://opposite-discussing-particles-maui.trycloudflare.com/api",
  headers: { "Content-Type": "application/json" },
});

export default api;
