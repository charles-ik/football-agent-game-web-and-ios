import { describe, expect, it } from "vitest";

import manifest from "./manifest";
import { appMetadata, appViewport } from "./pwa-metadata";

describe("iPhone PWA metadata", () => {
  it("launches as a portrait standalone app with install icons", () => {
    expect(manifest()).toMatchObject({
      id: "/",
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
          purpose: "any maskable",
        },
      ],
    });
    expect(appMetadata.manifest).toBe("/manifest.webmanifest");
    expect(appMetadata.appleWebApp).toMatchObject({
      capable: true,
      statusBarStyle: "black-translucent",
    });
    expect(appViewport).toMatchObject({
      width: "device-width",
      initialScale: 1,
      viewportFit: "cover",
    });
  });
});
