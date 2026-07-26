(() => {
  const countdown = document.querySelector("[data-launch-countdown]");
  if (!countdown) return;

  const target = new Date(countdown.dataset.launchTarget);
  const monthValue = countdown.querySelector("[data-countdown-months]");
  const dayValue = countdown.querySelector("[data-countdown-days]");
  const hourValue = countdown.querySelector("[data-countdown-hours]");
  const minuteValue = countdown.querySelector("[data-countdown-minutes]");
  const secondValue = countdown.querySelector("[data-countdown-seconds]");
  const monthMs = 30 * 24 * 60 * 60 * 1000;
  const dayMs = 24 * 60 * 60 * 1000;
  const hourMs = 60 * 60 * 1000;
  const minuteMs = 60 * 1000;

  function updateCountdown() {
    let remaining = Math.max(0, target.getTime() - Date.now());
    const months = Math.floor(remaining / monthMs);
    remaining -= months * monthMs;
    const days = Math.floor(remaining / dayMs);
    remaining -= days * dayMs;
    const hours = Math.floor(remaining / hourMs);
    remaining -= hours * hourMs;
    const minutes = Math.floor(remaining / minuteMs);
    remaining -= minutes * minuteMs;
    const seconds = Math.floor(remaining / 1000);

    monthValue.textContent = String(months).padStart(2, "0");
    dayValue.textContent = String(days).padStart(2, "0");
    hourValue.textContent = String(hours).padStart(2, "0");
    minuteValue.textContent = String(minutes).padStart(2, "0");
    secondValue.textContent = String(seconds).padStart(2, "0");
  }

  updateCountdown();
  window.setInterval(updateCountdown, 1000);
})();
