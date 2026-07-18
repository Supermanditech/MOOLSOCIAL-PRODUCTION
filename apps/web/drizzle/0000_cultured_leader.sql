CREATE TABLE `waitlist_leads` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`name` text NOT NULL,
	`email` text NOT NULL,
	`role` text NOT NULL,
	`city` text NOT NULL,
	`referral_code` text NOT NULL,
	`referred_by` text,
	`consent` integer DEFAULT true NOT NULL,
	`status` text DEFAULT 'waiting' NOT NULL,
	`source` text DEFAULT 'launch-page' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `waitlist_leads_email_unique` ON `waitlist_leads` (`email`);--> statement-breakpoint
CREATE UNIQUE INDEX `waitlist_leads_referral_code_unique` ON `waitlist_leads` (`referral_code`);--> statement-breakpoint
CREATE INDEX `waitlist_leads_role_city_idx` ON `waitlist_leads` (`role`,`city`);--> statement-breakpoint
CREATE INDEX `waitlist_leads_referred_by_idx` ON `waitlist_leads` (`referred_by`);