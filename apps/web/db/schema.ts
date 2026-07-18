import { sql } from "drizzle-orm";
import {
  index,
  integer,
  sqliteTable,
  text,
  uniqueIndex,
} from "drizzle-orm/sqlite-core";

export const waitlistLeads = sqliteTable(
  "waitlist_leads",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    name: text("name").notNull(),
    email: text("email").notNull(),
    role: text("role").notNull(),
    city: text("city").notNull(),
    referralCode: text("referral_code").notNull(),
    referredBy: text("referred_by"),
    consent: integer("consent", { mode: "boolean" }).notNull().default(true),
    status: text("status").notNull().default("waiting"),
    source: text("source").notNull().default("launch-page"),
    createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
    updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  },
  (table) => [
    uniqueIndex("waitlist_leads_email_unique").on(table.email),
    uniqueIndex("waitlist_leads_referral_code_unique").on(table.referralCode),
    index("waitlist_leads_role_city_idx").on(table.role, table.city),
    index("waitlist_leads_referred_by_idx").on(table.referredBy),
  ],
);
