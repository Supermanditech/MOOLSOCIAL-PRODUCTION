import { AccessDenied } from "@/components/AccessDenied";
import { AdminConsole } from "@/components/AdminConsole";
import { getAdminScreen } from "@/lib/admin-data";
import { requireAdminAccess } from "@/lib/admin-auth";

export const dynamic = "force-dynamic";

type AdminPageProps = {
  params: Promise<{ section?: string[] }>;
  searchParams: Promise<{ view?: string; failure?: string; mode?: string }>;
};

export default async function AdminPage({
  params,
  searchParams,
}: AdminPageProps) {
  const [{ section }, query] = await Promise.all([params, searchParams]);
  const access = requireAdminAccess();
  if (!access.allowed) {
    return <AccessDenied reason={access.reason ?? "Access denied."} />;
  }

  const pathname = section?.length
    ? `/admin/${section.join("/")}`
    : "/admin";
  const screen = getAdminScreen(pathname, query.view);

  return (
    <AdminConsole
      access={access}
      initialScreen={screen}
      failureMode={query.failure === "once"}
      commandMode={query.mode}
    />
  );
}
