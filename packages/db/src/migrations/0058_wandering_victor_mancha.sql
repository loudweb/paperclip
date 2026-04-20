ALTER TABLE "cost_events" ADD COLUMN "step_tag" text;--> statement-breakpoint
ALTER TABLE "cost_events" ADD COLUMN "task_kind" text;--> statement-breakpoint
CREATE INDEX "cost_events_company_step_occurred_idx" ON "cost_events" USING btree ("company_id","step_tag","occurred_at");