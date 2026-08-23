import { SocialContentError } from "./contracts.js";

export interface VerifiedSocialAppCheck {
  alreadyConsumed?: boolean;
}

export interface SocialRequestSecurityDependencies {
  verifyAppCheck(token: string, consume: boolean): Promise<VerifiedSocialAppCheck>;
  verifyIdToken(token: string): Promise<{ uid?: string }>;
}

export async function verifySocialInvocation(
  headers: Readonly<Record<string, string | string[] | undefined>>,
  dependencies: SocialRequestSecurityDependencies,
  consumeAppCheck: boolean,
  requireAuthentication = true,
): Promise<string | undefined> {
  const appCheckToken = header(headers, "x-firebase-appcheck");
  if (!appCheckToken) throw appVerificationRequired();
  try {
    const verified = await dependencies.verifyAppCheck(appCheckToken, consumeAppCheck);
    if (consumeAppCheck && verified.alreadyConsumed) throw appVerificationRequired();
  } catch (error) {
    if (error instanceof SocialContentError) throw error;
    throw appVerificationRequired();
  }

  const authorization = header(headers, "authorization");
  if (!requireAuthentication && !authorization) return undefined;
  if (!authorization?.startsWith("Bearer ")) throw authenticationRequired();
  const token = authorization.slice("Bearer ".length).trim();
  if (!token) throw authenticationRequired();
  try {
    const verified = await dependencies.verifyIdToken(token);
    if (!verified.uid) throw authenticationRequired();
    return verified.uid;
  } catch (error) {
    if (error instanceof SocialContentError) throw error;
    throw authenticationRequired();
  }
}

function header(
  headers: Readonly<Record<string, string | string[] | undefined>>,
  name: string,
): string | undefined {
  const value = headers[name] ?? headers[name.toLowerCase()];
  return Array.isArray(value) ? value[0] : value;
}

function appVerificationRequired(): SocialContentError {
  return new SocialContentError(
    "permission_denied",
    "App verification is required.",
    401,
  );
}

function authenticationRequired(): SocialContentError {
  return new SocialContentError(
    "authentication_required",
    "Sign in to continue.",
    401,
  );
}
