export type AdminAccess = {
  allowed: boolean;
  email?: string;
  role?: string;
  reviewMode: boolean;
  reason?: string;
};

export function requireAdminAccess(): AdminAccess {
  if (process.env.MOOLSOCIAL_ADMIN_REVIEW_MODE === "true") {
    return {
      allowed: true,
      email: "reviewer@moolsocial.local",
      role: "Superadmin Review",
      reviewMode: true,
    };
  }

  return {
    allowed: false,
    reviewMode: false,
    reason:
      "Production Superadmin access is unavailable until the Firebase session and server-side admin role claim are verified.",
  };
}
