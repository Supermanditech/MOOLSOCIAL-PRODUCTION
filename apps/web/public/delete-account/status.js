(() => {
  "use strict";

  const section = document.querySelector("[data-deletion-status]");
  const state = document.querySelector("[data-deletion-state]");
  const detail = document.querySelector("[data-deletion-detail]");
  if (!(section instanceof HTMLElement) ||
      !(state instanceof HTMLElement) ||
      !(detail instanceof HTMLElement)) {
    return;
  }

  const code = new URL(window.location.href).searchParams.get(
    "confirmation_code",
  )?.trim() ?? "";
  if (!/^[A-Za-z0-9_-]{16,64}$/u.test(code)) return;

  section.hidden = false;
  state.textContent = "Checking your request…";
  detail.textContent = "This usually takes only a moment.";

  const customerCopy = {
    pending: [
      "Deletion is in progress",
      "Your verified request is being completed. It will finish as soon as possible and no later than 30 days after it was received.",
    ],
    completed: [
      "Deletion is complete",
      "The MoolSocial data covered by this request has been deleted or permanently anonymized under our retention policy.",
    ],
    failed: [
      "Deletion needs attention",
      "We could not finish every deletion step. The request remains open for safe retry. Contact support if this status does not change.",
    ],
  };

  fetch(
    `/api/meta/data-deletion/status?confirmation_code=${encodeURIComponent(code)}`,
    {
      method: "GET",
      credentials: "omit",
      cache: "no-store",
      headers: { accept: "application/json" },
    },
  ).then(async (response) => {
    const raw = await response.text();
    if (raw.length > 4096) throw new Error("response_too_large");
    const body = JSON.parse(raw);
    const statusValue = body?.data?.state;
    if (!response.ok || body?.ok !== true || !(statusValue in customerCopy)) {
      throw new Error("status_unavailable");
    }
    const [heading, message] = customerCopy[statusValue];
    state.textContent = heading;
    detail.textContent = message;
  }).catch(() => {
    state.textContent = "Status is temporarily unavailable";
    detail.textContent =
      "Your request is still recorded. Try again later or contact hello@moolsocial.com for help.";
  });
})();
