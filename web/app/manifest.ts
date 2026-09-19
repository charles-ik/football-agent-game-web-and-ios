import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    id: "/",
    name: "Football Agent",
    short_name: "Football Agent",
    description: "Scout talent, represent clients, and build a football agency.",
    start_url: "/",
    display: "standalone",
    orientation: "portrait-primary",
    background_color: "#101b17",
    theme_color: "#17251f",
    icons: [
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      {
        src: "/icons/icon-512.png",
        sizes: "512x512",
        type: "image/png",
        purpose: "maskable",
      },
    ],
  };
}
