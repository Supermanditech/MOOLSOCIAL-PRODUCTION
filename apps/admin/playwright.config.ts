import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests",
  testMatch: /.*\.spec\.ts/,
  fullyParallel: false,
  forbidOnly: true,
  retries: 0,
  workers: 1,
  reporter: [["line"]],
  use: {
    baseURL: "http://localhost:3100",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [
    {
      name: "desktop-chromium",
      use: { ...devices["Desktop Chrome"], viewport: { width: 1440, height: 1000 } },
    },
    {
      name: "mobile-chromium",
      use: { ...devices["Pixel 7"], viewport: { width: 412, height: 915 } },
    },
  ],
  webServer: {
    command: "npm run build && npm run start",
    url: "http://localhost:3100/admin",
    reuseExistingServer: false,
    timeout: 180_000,
    env: {
      MOOLSOCIAL_ADMIN_REVIEW_MODE: "true",
    },
  },
});
