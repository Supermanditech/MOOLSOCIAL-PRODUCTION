export type AdminTone = "neutral" | "warning" | "critical" | "success";

export type AdminStat = {
  label: string;
  value: string;
  note: string;
};

export type AdminFact = {
  label: string;
  value: string;
};

export type AdminStep = {
  label: string;
  outcome: string;
};

export type AdminCase = {
  id: string;
  kicker: string;
  title: string;
  meta: string;
  status: string;
  tone: AdminTone;
  time: string;
  facts: AdminFact[];
  detail: string;
  steps: AdminStep[];
  currentStep: number;
  primary: string;
  secondary?: string;
  primaryOutcome: string;
  secondaryOutcome?: string;
  tags: string[];
  confirmation: string;
};

export type AdminScreen = {
  screen: number;
  navLabel: string;
  path: string;
  title: string;
  subtitle: string;
  role: string;
  stats: AdminStat[];
  filters: string[];
  queueTitle: string;
  queueNote: string;
  note: string;
  items: AdminCase[];
  composer?: boolean;
};

export type OfferingKind =
  | "Product"
  | "Service"
  | "Business-funded Reel"
  | "Guaranteed outcome"
  | "Funded work"
  | "Required action";

export type OfferingDraft = {
  targetProfile: string;
  kind: OfferingKind;
  title: string;
  userOutcome: string;
  eligibility: string;
  geography: string;
  maximumExposure: string;
  expiry: string;
  message: string;
  owner: string;
};

export const emptyOfferingDraft: OfferingDraft = {
  targetProfile: "",
  kind: "Guaranteed outcome",
  title: "",
  userOutcome: "",
  eligibility: "",
  geography: "",
  maximumExposure: "",
  expiry: "",
  message: "",
  owner: "",
};
