import type { SessionContextValue } from "next-auth/react";
import Link from "next/link";
import { useState, useEffect } from "react";

import { useLocale } from "@calcom/lib/hooks/useLocale";
import { TopBanner } from "@calcom/ui/components/top-banner";

export type AdminPasswordBannerProps = { data: SessionContextValue["data"] };

function getBannerMessageKey(reason: "both" | "password" | "2fa" | undefined): string {
  switch (reason) {
    case "password":
      return "invalid_admin_password_password_only";
    case "2fa":
      return "invalid_admin_password_2fa_only";
    case "both":
    default:
      return "invalid_admin_password";
  }
}

function getBannerAction(reason: "both" | "password" | "2fa" | undefined): { href: string; labelKey: string } {
  switch (reason) {
    case "2fa":
      return { href: "/settings/security/two-factor-auth", labelKey: "enable_2fa" };
    case "password":
    case "both":
    default:
      return { href: "/settings/security/password", labelKey: "change_password_admin" };
  }
}

function AdminPasswordBanner({ data }: AdminPasswordBannerProps) {
  const { t } = useLocale();
  const [dismissed, setDismissed] = useState(false);

  useEffect(() => {
    if (data?.user.id) {
      const dismissKey = `admin-banner-dismissed-${data.user.id}`;
      try {
        if (localStorage.getItem(dismissKey) === "true") {
          setDismissed(true);
        }
      } catch {
        // localStorage not available
      }
    }
  }, [data?.user.id]);

  if (data?.user.role !== "INACTIVE_ADMIN") return null;
  if (dismissed) return null;

  const messageKey = getBannerMessageKey(data.user.inactiveAdminReason);
  const { href, labelKey } = getBannerAction(data.user.inactiveAdminReason);

  const handleDismiss = () => {
    if (data?.user.id) {
      const dismissKey = `admin-banner-dismissed-${data.user.id}`;
      try {
        localStorage.setItem(dismissKey, "true");
      } catch {
        // localStorage not available
      }
    }
    setDismissed(true);
  };

  return (
    <>
      <TopBanner
        text={t(messageKey, { user: data.user.username })}
        variant="warning"
        actions={
          <div className="flex items-center gap-4">
            <Link href={href} className="border-b border-b-black">
              {t(labelKey)}
            </Link>
            <button
              onClick={handleDismiss}
              className="ml-2 inline-flex h-5 w-5 items-center justify-center rounded text-emphasis hover:bg-black/10 hover:text-black"
              aria-label="Close banner"
              title="Close">
              ✕
            </button>
          </div>
        }
      />
    </>
  );
}

export default AdminPasswordBanner;
