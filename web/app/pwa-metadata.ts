import type { Metadata, Viewport } from "next";

export const appMetadata: Metadata = {
  title: "Football Agent",
  description: "Scout on incomplete information, sign clients, take your cut.",
  applicationName: "Football Agent",
  manifest: "/manifest.webmanifest",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Football Agent",
  },
  icons: { apple: "/icons/apple-touch-icon.png" },
};

export const appViewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  colorScheme: "dark",
  themeColor: "#17251f",
};
